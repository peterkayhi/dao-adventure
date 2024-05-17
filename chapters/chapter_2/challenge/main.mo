import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Types "types";
actor {

    type Member = Types.Member;
    type Result<Ok, Err> = Types.Result<Ok, Err>;
    type HashMap<K, V> = Types.HashMap<K, V>;

    let members = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash); // create hashmap 'members' with Principal as the hash/name and Member as the value. ??unclear why this works as immutable 

    // hashmap has size 0 and uses Principal's equal & hash functions to instantiate

    public shared ({ caller }) func addMember(member : Member) : async Result<(), Text> { // given member, return a Result (i.e. error or OK). { caller } extracts principal (guid) of the user or canister that is calling the function
        switch (members.get(caller)) { //use caller has to find a member
            case (null) { // doesn't exist
                members.put(caller, member);
                return #ok();
            }; // add member using caller's hash and return ok
            case (?member) {
                return #err("Member already exists");
            };
        };    
    };

    public query func getMember(p : Principal) : async Result<Member, Text> {
        switch (members.get(p)) { // search given Principle hash/key
            case (null) { //not found
                return #err("Member does not exist");
            };
            case (?member) { //member or something found
                return #ok(member);
            };
        };
    };

    public query ({ caller }) func getCaller() : async Result<Member, Text> {
        switch (members.get(caller)) { // search given caller Principle hash/key
            case (null) { //not found
                return #err("Caller is not a Member");
            };
            case (?member) { //member or something found
                return #ok(member);
            };
        };
    };


    public shared ({ caller }) func updateMember(updMember : Member) : async Result<(), Text> { // given caller's principle, update their record if they exist and return populated Result
        switch (members.get(caller)) { // get the caller's member record
            case (null) { // not there
                return #err("Member does not exist");
            };
            case (?member) { // unbound found ?? why use unbound - why not just member instead of ?member
                members.put(caller, updMember); //overwrite existing member data
                return #ok();
            };
        };
    };

    public query func getAllMembers() : async [Member] { // return array of Member
        return Iter.toArray(members.vals()); // iterate across all the values of the members ?? why declare the Iter.toArray type? .vals is of type Iter already.        
    };

    public query func numberOfMembers() : async Nat {
        return members.size();
    };

    public shared ({ caller }) func removeMember() : async Result<(), Text> {  
        switch (members.get(caller)) { // use caller's Principal (guid) to lookup and if exists
            case (null) { //not found
                return #err("Member does not exist");
            };
            case (?member) { //exists
                members.delete(caller);
                return #ok();
            };
        };
    };

};