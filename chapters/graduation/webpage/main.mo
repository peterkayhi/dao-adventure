
import Result "mo:base/Result";
import Types "types";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
actor Webpage {

    type Result<A, B> = Result.Result<A, B>;
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;

    // The manifesto stored in the webpage canister should always be the same as the one stored in the DAO canister
    stable var manifesto : Text = "Develop a community-owned network of buyers that effectively captures their marketing value";
    let gradDaoIdText : Text = "ofoea-eyaaa-aaaab-qab6a-cai";
    stable let gradDaoIdWebpage : Principal = Principal.fromText(gradDaoIdText); // set w/ canister ID of the graduation DAO

    let logo : Text = "<svg width='800px' height='800px' viewBox='0 0 24 24' id='Layer_1' data-name='Layer 1' xmlns='http://www.w3.org/2000/svg'><defs><style>.cls-1{fill:none;stroke:#020202;stroke-miterlimit:10;stroke-width:1.91px;}</style></defs><circle class='cls-1' cx='12' cy='3.43' r='1.91'/><path class='cls-1' d='M9.14,8.2h0A2.86,2.86,0,0,1,12,5.34h0A2.86,2.86,0,0,1,14.86,8.2h0'/><circle class='cls-1' cx='19.64' cy='18.7' r='1.91'/><path class='cls-1' d='M16.77,23.48h0a2.87,2.87,0,0,1,2.87-2.87h0a2.87,2.87,0,0,1,2.86,2.87h0'/><circle class='cls-1' cx='4.36' cy='18.7' r='1.91'/><path class='cls-1' d='M1.5,23.48h0a2.87,2.87,0,0,1,2.86-2.87h0a2.87,2.87,0,0,1,2.87,2.87h0'/><line class='cls-1' x1='12' y1='9.16' x2='12' y2='13.93'/><polyline class='cls-1' points='8.18 16.8 12 13.93 15.82 16.8'/></svg>";
    
    let name = "OhMana";

    var lastCaller : Text = "Not Called Yet"; // we're going to save and publish this

    func _getWebpage() : Text {  // internal routine that creates html content for later display
        var webpage = "<style>" #
        "body { text-align: center; font-family: Arial, sans-serif; background-color: #f0f8ff; color: #333; }" #
        "h1 { font-size: 3em; margin-bottom: 10px; }" #
        "hr { margin-top: 20px; margin-bottom: 20px; }" #
        "em { font-style: italic; display: block; margin-bottom: 20px; }" #
        "ul { list-style-type: none; padding: 0; }" #
        "li { margin: 10px 0; }" #
        "li:before { content: '👉 '; }" #
        "svg { max-width: 150px; height: auto; display: block; margin: 20px auto; }" #
        "h2 { text-decoration: underline; }" #
        "</style>";

        webpage := webpage # "<div><h1>" # name # "</h1></div>";
        webpage := webpage # "<em>" # manifesto # "</em>";
        // debug webpage := webpage # "<div><h2>Last Caller: " # lastCaller # "</h2></div>";        
        webpage := webpage # "<div>" # logo # "</div>";
        webpage := webpage # "<hr>";
        return webpage;
    };


    // The webpage displays the manifesto

    public query func http_request(request : HttpRequest) : async HttpResponse {
        return ({
            headers = [("Content-Type", "text/html; charset=UTF-8")];
            status_code = 200 : Nat16;
            body = Text.encodeUtf8(_getWebpage());
            streaming_strategy = null;
        });
    };
    
    // This function should only be callable by the DAO canister (no one else should be able to change the manifesto)
    public shared ({ caller }) func setManifesto(newManifesto : Text) : async Result<(), Text> {
        lastCaller := Principal.toText(caller); // get a copy of this caller to display on web page.
        if ((lastCaller) != gradDaoIdText) {  // is this the right caller?
            // debug lastCaller := lastCaller # ":Failed";
            return #err("Only the DAO canister can change the manifesto")
        } else { // yes, 
            // debug lastCaller := lastCaller # ":Passed";
            manifesto := newManifesto;  // update the manifiest
            return #ok();
        };
    };
};
