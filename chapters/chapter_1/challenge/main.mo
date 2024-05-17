import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
actor {

  let name : Text = "OhMana";
  var manifesto : Text = "Develop a community-owned network of buyers that effectively captures the value of their marketing power";
  let goals : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);

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
        goals.add(newGoal); // add to the stack
        return;
    };

    public shared query func getGoals() : async [Text] {
       return Buffer.toArray(goals); //return all the goals
    };
};