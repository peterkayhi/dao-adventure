import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Types "types";
import Nat64 "mo:base/Nat64";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Time "mo:base/Time";
import Array "mo:base/Array";

actor {
    // For this level we need to make use of the code implemented in the previous projects.
    // The voting system will make use of previous data structures and functions.
    /////////////////
    //   TYPES    //
    ///////////////
    type Member = Types.Member;
    type Result<Ok, Err> = Types.Result<Ok, Err>;
    type HashMap<K, V> = Types.HashMap<K, V>;
    type Proposal = Types.Proposal;
    type ProposalContent = Types.ProposalContent;
    type ProposalId = Types.ProposalId;
    type Vote = Types.Vote;

    /////////////////
    // PROJECT #1 //
    ///////////////
    let goals = Buffer.Buffer<Text>(0);
    let name = "OhMana";
    var manifesto = "Develop a community-owned network of buyers that effectively captures the value of their marketing power";

    public shared query func getName() : async Text {
        return name;
    };

    public shared query func getManifesto() : async Text {
        return manifesto;
    };

    public func setManifesto(newManifesto : Text) : async () {
        manifesto := newManifesto;
        return;
    };

    public func addGoal(newGoal : Text) : async () {
        goals.add(newGoal);
        return;
    };

    public shared query func getGoals() : async [Text] {
        Buffer.toArray(goals);
    };

    /////////////////
    // PROJECT #2 //
    ///////////////
    let members = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash);

    public shared ({ caller }) func addMember(member : Member) : async Result<(), Text> {
        switch (members.get(caller)) {
            case (null) {
                members.put(caller, member);
                return #ok();
            };
            case (?member) {
                return #err("Member already exists");
            };
        };
    };

    public shared ({ caller }) func updateMember(member : Member) : async Result<(), Text> {
        switch (members.get(caller)) {
            case (null) {
                return #err("Member does not exist");
            };
            case (?member) {
                members.put(caller, member);
                return #ok();
            };
        };
    };

    public shared ({ caller }) func removeMember() : async Result<(), Text> {
        switch (members.get(caller)) {
            case (null) {
                return #err("Member does not exist");
            };
            case (?member) {
                members.delete(caller);
                return #ok();
            };
        };
    };

    public query func getMember(p : Principal) : async Result<Member, Text> {
        switch (members.get(p)) {
            case (null) {
                return #err("Member does not exist");
            };
            case (?member) {
                return #ok(member);
            };
        };
    };

    public query func getAllMembers() : async [Member] {
        return Iter.toArray(members.vals());
    };

    public query func numberOfMembers() : async Nat {
        return members.size();
    };

    /////////////////
    // PROJECT #3 //
    ///////////////
    let ledger = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);

    public query func tokenName() : async Text {
        return "Motoko Bootcamp Token";
    };

    public query func tokenSymbol() : async Text {
        return "MBT";
    };

    public func mint(owner : Principal, amount : Nat) : async Result<(), Text> {
        let balance = Option.get(ledger.get(owner), 0);
        ledger.put(owner, balance + amount);
        return #ok();
    };

    public func burn(owner : Principal, amount : Nat) : async Result<(), Text> {
        let balance = Option.get(ledger.get(owner), 0);
        if (balance < amount) {
            return #err("Insufficient balance to burn");
        };
        ledger.put(owner, balance - amount);
        return #ok();
    };

    func _burn(owner : Principal, amount : Nat) : () {  // _ underscore is a convention meaning local synchronous function
        let balance = Option.get(ledger.get(owner), 0);
        ledger.put(owner, balance - amount);
        return;
    };

    public shared ({ caller }) func transfer(from : Principal, to : Principal, amount : Nat) : async Result<(), Text> {
        let balanceFrom = Option.get(ledger.get(from), 0);
        let balanceTo = Option.get(ledger.get(to), 0);
        if (balanceFrom < amount) {
            return #err("Insufficient balance to transfer");
        };
        ledger.put(from, balanceFrom - amount);
        ledger.put(to, balanceTo + amount);
        return #ok();
    };

    public query func balanceOf(owner : Principal) : async Nat {
        return (Option.get(ledger.get(owner), 0));
    };

    public query func totalSupply() : async Nat {
        var total = 0;
        for (balance in ledger.vals()) {
            total += balance;
        };
        return total;
    };
    /////////////////
    // PROJECT #4 //
    ///////////////

    var nextProposalId : Nat64 = 0;
    let proposals = HashMap.HashMap<ProposalId, Proposal>(0, Nat64.equal, Nat64.toNat32);

    public shared ({ caller }) func createProposal(content : ProposalContent) : async Result<ProposalId, Text> {
        switch (members.get(caller)) { //use caller's hash to see if they exist as a member
            case (null) {
                return #err("The caller is not a member - cannot create a proposal");
            };
            case (?member) { // member exists
                let balance = Option.get(ledger.get(caller), 0); //get caller's balance or 0 if null
                if (balance < 1) {
                    return #err("The caller does not have enough tokens to create a proposal");
                };
                // Create the proposal and burn the tokens
                let proposal : Proposal = { // types.mo details out this structure
                    id = nextProposalId;
                    content; // AKA content = content;
                    creator = caller;
                    created = Time.now();
                    executed = null;
                    votes = []; // init to empty array
                    voteScore = 0;
                    status = #Open;
                };
                proposals.put(nextProposalId, proposal); // add above var to proposals hashmap
                nextProposalId += 1;  // inc for next proposal created
                _burn(caller, 1);  // burn 1 token from caller ledger balance
            //    return #ok(proposal.id); why not this??
                return #ok(nextProposalId - 1); //-1 b/c 
            };
        };
    };

    public query func getProposal(proposalId : ProposalId) : async ?Proposal { // given a ProposalId, optionally (via ?) return a proposal
        return proposals.get(proposalId);
    };

    public shared ({ caller }) func voteProposal(proposalId : ProposalId, vote: Vote) : async Result<(), Text> {
        // Check if the caller is a member of the DAO
        switch (members.get(caller)) {
            case (null) { // no member found
                return #err("Caller must be a member to vote on proposal");
            };
            case (?member) { // member found
                // Check if the proposal exists
                switch (proposals.get(proposalId)) {
                    case (null) { // no proposal
                        return #err("The proposal does not exist");
                    };
                    case (?proposal) { // proposal found
                        // Check if the proposal is open for voting
                        if (proposal.status != #Open) {  // not open
                            return #err("The proposal is not open for voting");
                        };
                        // Check if the caller has already voted
                        if (_hasVoted(proposal, caller)) {
                            return #err("The caller has already voted on this proposal");
                        };
                        // process the vote
                        let balance = Option.get(ledger.get(caller), 0); // get caller's ledger balance or 0 if null
                        let multiplierVote = switch (vote.yesOrNo) {
                            case (true) { 1 };
                            case (false) { -1 };
                        }; //vote yes is positive, vote no is negative
                        let newVoteScore = proposal.voteScore + balance * multiplierVote; // adjust proposal's vote score by this caller's vote
                        var newExecuted : ?Time.Time = null; //default to null time unless executed
                        let newVotes = Buffer.fromArray<Vote>(proposal.votes); // convert so we can manipulate
                        newVotes.add({ // add callers's vote to buffer
                            member = caller;
                            votingPower = balance;
                            yesOrNo = vote.yesOrNo;                     
                        });
                        let newStatus = if (newVoteScore >= 100) { // Assign to newStatus the result: did Proposal's vote status change as a result of this vote?
                            #Accepted;
                        } else if (newVoteScore <= -100) {
                            #Rejected;
                        } else { // not over 100 or under -100
                            #Open;
                        };
                        switch (newStatus) { // do anything?
                            case (#Accepted) { // yes, execute
                                _executeProposal(proposal.content);
                                newExecuted := ?Time.now(); // update accepted proposal's execution time
                            };
                            case (_) {};  // catch all 
                        };
                        let newProposal : Proposal = { //create temp var to hold updated proposal data
                            id = proposal.id; 
                            content = proposal.content;
                            creator = proposal.creator;
                            created = proposal.created;
                            executed = newExecuted;
                            votes = Buffer.toArray(newVotes);  // copy over the updated buffer from above
                            voteScore = newVoteScore;
                            status = newStatus;
                        };
                        proposals.put(proposal.id, newProposal); // update previous proposal with new.
                        return #ok();
                    };
                };
            };
        };

    };

    func _hasVoted(proposal : Proposal, member : Principal) : Bool {
        return Array.find<Vote>(
            proposal.votes,
            func(vote : Vote) {
                return vote.member == member;
            }, // search through the array of type Vote in the proposal.votes structure. Find a Vote.member that == the member passed in the parameter and return that Vote if found.
        ) != null; // array.find result will not be null if something was found, therefore returns TRUE to _hasVoted if found
    };

    func _executeProposal(content : ProposalContent) : () {
        switch (content) {
            case (#ChangeManifesto(newManifesto)) {
                manifesto := newManifesto;
            };
            case (#AddGoal(newGoal)) {
                goals.add(newGoal);
            };
        };
        return;
    };

    public query func getAllProposals() : async [Proposal] {
        return [];
    };
};