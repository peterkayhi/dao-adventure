import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import HashMap "mo:base/HashMap";
import Types "types";
actor {

    type Result<Ok, Err> = Types.Result<Ok, Err>;
    type HashMap<K, V> = Types.HashMap<K, V>;
    let ledger = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);
    let nameOfToken : Text = "Mana";
    let symbolOfToken : Text = "ANA";

    public query func tokenName() : async Text {
        return nameOfToken;
    };

    public query func tokenSymbol() : async Text {
        return symbolOfToken;
    };

    public func mint(owner : Principal, amount : Nat) : async Result<(), Text> {
        let balance = Option.get(ledger.get(owner), 0); // get balance from ledger given owner hash
        ledger.put(owner, balance + amount); // add amount to balance and save as new balance to owner hashmap
        return #ok();
    };

    public func burn(owner : Principal, amount : Nat) : async Result<(), Text> {
        let balance = Option.get(ledger.get(owner), 0); // get balance from owner ledget
        if (balance < amount) {
            return #err("Insufficient balance to burn");
        }; // can't reduce balance by amount
        ledger.put(owner, balance - amount); // otherwise subtract from balance and save
        return #ok();
    };

    public shared ({ caller }) func transfer(from : Principal, to : Principal, amount : Nat) : async Result<(), Text> {
        if (from == to) {
            return #err("Cannot transfer to self");
        }; // well you could transfer to yourself ?? but that wouldn't do anything 
        let balanceFrom = Option.get(ledger.get(from), 0); // get balance of the from and if null, return zero
        let balanceTo = Option.get(ledger.get(to), 0); // get balance of the destination and if null, return zero
        if (balanceFrom < amount) {
            return #err("Insufficient balance to transfer");
        };  // enough in the from balance to transfer?
        ledger.put(from, balanceFrom - amount); // subtract the from balance by amount
        ledger.put(to, balanceTo + amount); // and add that amount to the to balance
        return #ok();

    };

    public query func balanceOf(account : Principal) : async Nat {
        return (Option.get(ledger.get(account), 0)); // get balance and if null return 0
    };

    public query func totalSupply() : async Nat {
        var total = 0;
        for (balance in ledger.vals()) {
            total += balance;
        }; //iterate over each value and increment total
        return total;

    };

};