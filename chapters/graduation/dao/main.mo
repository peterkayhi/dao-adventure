import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Types "types";
import Array "mo:base/Array";

actor {

        type Result<A, B> = Result.Result<A, B>;
        type Member = Types.Member;
        type ProposalContent = Types.ProposalContent;
        type ProposalId = Types.ProposalId;
        type Proposal = Types.Proposal;
        type Vote = Types.Vote;
        type HttpRequest = Types.HttpRequest;
        type HttpResponse = Types.HttpResponse;

        // The principal of the Webpage canister associated with this DAO canister (needs to be updated with the ID of your Webpage canister)
        let webCanisterIdText = "ocpcu-jaaaa-aaaab-qab6q-cai";
        stable let canisterIdWebpage : Principal = Principal.fromText(webCanisterIdText);
        stable var manifesto = "Develop a community-owned network of buyers that effectively captures their marketing value";
        stable let daoName = "OhMana";
        stable var goals = [];
        let members = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash);
        var nextProposalId : Nat64 = 0;
        let proposals = HashMap.HashMap<ProposalId, Proposal>(0, Nat64.equal, Nat64.toNat32);

        let mbtCanister = actor("jaamb-mqaaa-aaaaj-qa3ka-cai") : actor {
                balanceOf : shared query Principal -> async Nat;
                balanceOfArray : shared query [Principal] -> async [Nat];
                burn : shared (Principal, Nat) -> async Result<(), Text>;
                mint : shared (Principal, Nat) -> async Result<(), Text>;
                tokenName : shared query () -> async Text;
                tokenSymbol : shared query () -> async Text;
                totalSupply : shared query () -> async Nat;
                transfer : shared (Principal, Principal, Nat) -> async Result<(), Text>;   
        };

        // create reference to the web canister
        // update actor with current ID of web canister
        let webCanister = actor (webCanisterIdText) : actor {
                setManifesto : shared (Text) -> async Result<(), Text>;
        };

        // mine:  gets the mbt balance of any principal getBalance(p:Principal)

        // Returns the name of the DAO
        public query func getName() : async Text {
                return daoName;
        };

        // Returns the manifesto of the DAO
        public query func getManifesto() : async Text {
                manifesto;
        };

        // Returns the goals of the DAO
        public query func getGoals() : async [Text] {
                return goals;
        };

        // Register a new member in the DAO with the given name and principal of the caller
        public shared ({ caller }) func registerMember(member : Member) : async Result<(), Text> {
                switch (members.get(caller)) {
                        case (null) { // not found, add new member
                                let newMember : Member = {
                                        name = member.name; // use name passed in the function
                                        role = #Student; // new members always students
                                };
                                members.put(caller, newMember); // add new mewmber                    
                                return (await mbtCanister.mint(caller,10) );  // Airdrop 10 MBC tokens to the new member and return passed Result. This direct return works because the function's return definition is identical to the mbtoken function's return definition. (Result<(), Text>)
                        };
                        case (?member) {
                                return #err("Member already exists");
                                     // Returns an error if the member already exists
                         };
                };
        };

        // mine: like registerMember except it doesn't access {caller} and instead allows any principal to be added addMember(p : Principal, name : Text)
       

        // like addMember except it creates special case Mentors as members 
        func _addMentorMember(principalText : Text , name : Text) : () {
                let p : Principal = Principal.fromText(principalText);
                switch (members.get(p)) {
                        case (null) { // not found, add new member
                                let newMember : Member = {
                                        name; // use name passed in the function
                                        role = #Mentor; // create as Mentor
                                };
                                members.put(p, newMember); // add newMember
                        };
                        case (?member) {}; // assuming this case (member exists) cannot happen
                };
        };

        // mine: lets you openly edit mbt balances  mbtEdit (p : Principal, qty: Int)

        // Get the member with the given principal
        // Returns an error if the member does not exist
        public query func getMember(p : Principal) : async Result<Member, Text> {
                switch (members.get(p)) {
                        case (?member) {
                                return #ok(member);
                        };
                        case (null) {
                                return #err("Member does not exist");
                        };
                };
        };
        // Graduate the student with the given principal   
        public shared ({ caller }) func graduate(student : Principal) : async Result<(), Text> {
                switch (members.get(caller)) { // confirm caller is qualified
                        case (null) {
                                return #err("Caller not a member");
                        };
                        case (?member) {
                                if (member.role != #Mentor) {
                                        return #err ("Caller must be a Mentor to create a proposal");
                                };
                        };
                };
                switch (members.get(student)) { // Returns an error if the student does not exist or is not a student
                        case (null) { // caller is not a member
                                return #err("Student does not exist");
                        };
                        case (?member) { //student is member
                                switch (member.role) {  // now confirm role before we graduate
                                        case (#Graduate) {  
                                                return #err ("Member already graduated");
                                        };
                                        case (#Mentor) {
                                                return #err ("Member is a Mentor and Mentors canʻt be graduated any futher");
                                        };
                                        case (#Student) { // Student is the only role that can get graudated
                                                var gradMember : Member = { // setup the temp so we can delete/recreate the updated student record
                                                        role = #Graduate; // youʻre now a grad
                                                        name = member.name; 
                                                };
                                                members.delete(student); //out with the old
                                                members.put (student, gradMember); //and in w/ the new
                                                return (#ok);
                                        }; 
                                };

                        };
                };
        };

        // Create a new proposal and returns its id  ??
        // Returns an error if the caller is not a mentor or doesn't own at least 1 MBC token
        // ChangeManifesto: those proposals contain a Text that if approved will be the new manifesto of the DAO. If the proposal is approved the changes should be reflected on the DAO canister and the Webpage canister. 
        // AddMentor: those proposals contain a Principal that if approved will become a mentor of the DAO. Whenever such a proposal is created, we need to verify that the specified principal is a Graduate of the DAO, as only Graduate can become Mentors. If the proposal is approved the changes should be reflected on the DAO canister.
        public shared ({ caller }) func createProposal(content : ProposalContent) : async Result<ProposalId, Text> {
                switch (members.get(caller)) { // confirm caller is qualified
                        case (null) {
                                return #err("Caller not a member");
                        };
                        case (?member) {
                                if (member.role != #Mentor) {
                                        return #err ("Caller must be a Mentor to graduate a student");
                                };
                                // ok it's a Mentor
                                var mbtBalance : Nat = await mbtCanister.balanceOf(caller); // does Mentor have enough mbt?
                                if (mbtBalance < 1) {
                                        return #err ("Memtor must have at least 1 MBT");
                                } else { // create the proposal
                                        switch (content) { // what kine proposal is it?
                                                case (#AddMentor(graduatePrincipalId)) { // upgrade member to Mentor
                                                        switch (members.get(graduatePrincipalId)) { // validate this member
                                                                case (null) { // is grad a member at all?
                                                                        return #err("Mentor candidate is not a member")
                                                                };
                                                                case (?member) {
                                                                        if (member.role != #Graduate) {
                                                                                return #err ("Mentor candidate must be a Graduate to be promoted")
                                                                        };
                                                                };
                                                        };

                                                };
                                                case (_) { }; // the other proposal types don't need special processing
                                       };                                
                                        // burn 1 mbt to create
                                        let burnVar = await mbtCanister.burn(caller, 1);
                                        switch (burnVar) { // did it work?
                                                case (#err(mbtBurnErrorText)) { // no burn
                                                        return #err(mbtBurnErrorText);
                                                };
                                                case (#ok(mbtOkText)) { // burn happened
                                                        var newProposal : Proposal = {
                                                                id = nextProposalId;
                                                                content = content; //   passed in function
                                                                creator = caller;
                                                                created = Time.now();
                                                                executed = null;
                                                                votes = [];
                                                                voteScore = 0;
                                                                status = #Open;
                                                        };
                                                        proposals.put(newProposal.id, newProposal); // create the proposal
                                                        nextProposalId += 1; // bump up for next proposal
                                                        return #ok(newProposal.id); // return the ProposalId from newProposal 
                                                 };
                                        };
  
                                }; 
                        };
                };
        };


        // Get the proposal with the given id
        // Returns an error if the proposal does not exist
        public query func getProposal(id : ProposalId) : async Result<Proposal, Text> {
                switch(proposals.get(id)) { // get the proposal given the passed id
                        case (null) {  // not found
                                return #err("Proposal Not Found");
                        };
                        case (?proposal) {  // return it
                                return #ok(proposal);
                        };
                };
        };

        // Returns all the proposals
        public query func getAllProposal() : async [Proposal] {
                let props = Buffer.Buffer<Proposal>(0);
                for ((propId, tempProp) in proposals.entries()) {
                        props.add(tempProp); // add the proposal to the Buffer
                };
                let propArray : [Proposal] = Buffer.toArray<Proposal>(props); //convert buffer to array
                return propArray; // and return it
        };

        // mine: Returns all members  getAllMembers() 

        // Vote for the given proposal
        // Returns an error if the proposal does not exist or the member is not allowed to vote
        public shared ({ caller }) func voteProposal(proposalId : ProposalId, yesOrNo : Bool) : async Result<(), Text> {
                // only grads and mentors are allowed to vote
                var votePower : Nat = 0; // holds member's voting power multiple
                var voteUpOrDown : Int = 0; // will be -1 or 1 based on yesOrNo parameter
                switch (members.get(caller)) { // lookup member
                        case (null) { // not found
                                return #err("The caller is not a member - canno vote one proposal");
                        };
                        case (?member) { // found
                                switch(member.role) {
                                        case (#Student) { // no can vote
                                                return #err("Students cannot vote");
                                        };
                                        case (#Graduate) { // grad power = 1X of MBT
                                                votePower := 1;
                                        };
                                        case (#Mentor) { // Mentor power = 5x MBT
                                                votePower := 5;
                                        };
                                };
                                switch (proposals.get(proposalId)) { //work on proposal now
                                        case (null) {
                                                return #err("No such proposal ID")
                                        };
                                        case (?proposal) {  // gotit
                                                if (proposal.status != #Open) { // must be Open
                                                        return #err("Proposal not Open for Voting");
                                                };
                                                if (_hasVoted(proposal, caller)) {  // check if caller has voted
                                                        return #err ("This caller has already voted");
                                                };
                                                let mbtBalance : Nat = await mbtCanister.balanceOf(caller); // get caller's MBT balance (for voting)
                                                if (yesOrNo) { // vote is in favor
                                                        voteUpOrDown := 1; // therefore positive
                                                } else {
                                                        voteUpOrDown := -1; // voting against, therefore negative
                                                };
                                                let memberVotingPower : Nat = votePower * mbtBalance; // calculate their voting power
                                                let newVoteScore = proposal.voteScore + ( memberVotingPower * voteUpOrDown) ; // adjust proposal vote total by memberVoting Power
                                                var newExecuted : ?Time.Time = null; // init this for later use - will only get changed if the proposal got executed
                                                let newVotes = Buffer.fromArray<Vote>(proposal.votes); // convert to buffer so we can append new values
                                                let addedVote : Vote = {
                                                        member = caller;
                                                        votingPower = memberVotingPower; // votingPower is Nat, and 
                                                        yesOrNo = yesOrNo;
                                                };
                                                newVotes.add(addedVote); // add this caller's vote to the array of votes in the proposal
                                                let newStatus = if (newVoteScore >= 100) { // update proposal status
                                                        #Accepted;  //A proposal is automatically accepted if the voteScore reaches 100 or more.
                                                } else if (newVoteScore <= -100) {
                                                        #Rejected;  // A proposal is automatically rejected if the voteScore reaches -100 or less. 
                                                } else {
                                                        #Open // A proposal stays open as long as it's not approved or rejected.
                                                };
                                                switch (newStatus) {
                                                        case (#Accepted) { // execute the proposal
                                                                var execProp = _executeProposal(proposal.content); // ?? why can't I do a switch/case based on the result of the call 
                                                                newExecuted := ?Time.now();  // timestamp execution time
                                                        };
                                                        case (_) {}; //we don't care about the other statuses
                                                };
                                                let newProposal : Proposal = { // create the updated proposal record
                                                        id = proposal.id;  // unchanged from original proposal
                                                        content = proposal.content; // unchanged from original proposal
                                                        creator = proposal.creator; // unchanged from original proposal
                                                        created = proposal.created; // unchanged from original proposal
                                                        executed = newExecuted; // either null or the time this proposal got executed 
                                                        votes = Buffer.toArray<Vote>(newVotes); // updated votes
                                                        voteScore = newVoteScore; // updated score 
                                                        status = newStatus; // updated status
                                                };
                                                proposals.put(proposal.id, newProposal); // and save the updated proposal
                                                return #ok;
                                        };
                                };
                        };

                };
        };

        func _hasVoted (proposal : Proposal, member : Principal) : Bool {
                return Array.find<Vote> (
                        proposal.votes, // search in the votes array
                        func (vote: Vote) {
                                return vote.member == member; // and find a vote from this member
                        },
                ) != null;  // != null result in the find means member was found, returning TRUE. == null means member not found, i.e. returns FALSE

        };

        func _executeProposal (content: ProposalContent) : async Result<(), Text> {
                switch (content) {
                        case (#ChangeManifesto(newManifesto)) { // update the manifesto
                                manifesto := newManifesto;
                                return (await webCanister.setManifesto(manifesto) ); // update web canister w/ new manifesto and return whatever it tells us
                        };
                        case (#AddMentor(newMentor)) { //graduate member to mentor. newMentor holds principal (index) of member
                                switch (members.get(newMentor)) {
                                        case (null) {
                                                return #err("members.get failed within _executeProposal")
                                        }; // not found - should not happen but I can't return an error here
                                        case (?member) { // found member 
                                                let updatedMember : Member = { // create updated member record
                                                        name = member.name; // use existing name
                                                        role = #Mentor; // and update their new role
                                                };
                                                members.put(newMentor, updatedMember); // save it
                                                return #ok();
                                        };

                                };

                        };
                        case (_) {
                                return #ok();
                        };  // don't care about other cases - probably remove #AddGoal as content type
                };

        };

        // Returns the Principal ID of the Webpage canister associated with this DAO canister
        public query func getIdWebpage() : async Principal {
                // return canisterIdWebpage;
                return Principal.fromText(webCanisterIdText);
        };
        //run once to initialize canister
       
        func _canister_init3() : () {
                // add bootcamp mentor
                _addMentorMember ("nkqop-siaaa-aaaaj-qa3qq-cai","motoko_bootcamp" ); 

                //now add me as a mentor (see 2464747 identity in notes)        
                _addMentorMember ("kzlvz-6ghra-dkc5p-iycjh-cyuc5-q5h4y-txapp-d44f5-fom52-qpulx-sae","PkCanister Mentor" );
        };

        _canister_init3(); // one-time init when canister executes
};
