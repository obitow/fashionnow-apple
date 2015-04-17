Parse.Cloud.define("sendPush", function (request, response) {
    "use strict";
    var query = new Parse.Query(Parse.Installation);
    query.containedIn("userId", request.params.userIds);

    Parse.Push.send({
        where: query,
        data: {
            alert: request.params.senderName + " precisa de ajuda!",
            badge: "Increment"
        }
    }, {
        succes: function () {
            // Push successfull
            response.success("Push sent");
        },
        error: function (error) {
            // Handle error
            response.error("Error");
        }
    });
});

//IDEIA: UM CLOUD CODE QUE DEVOLVE O COUNT DAS DUAS OPCOES DA ENQUETE

Parse.Cloud.afterSave("Poll", function (request) {
    "use strict";
    
    if (request.object.get("version") <= 1) {
        
        var query = new Parse.Query(Parse.Installation);
        query.containedIn("userId", request.object.get("userIds"));

        Parse.Push.send({
            where: query,
            data: {
                alert: request.user.get("name") + " precisa de ajuda!",
                badge: "Increment"
            }
        }, {
            succes: function () {
                // Push successfull
                console.log("Push sent");
            },
            error: function (error) {
                // Handle error
                console.error("Error send push");
            }
        });
    }
});

Parse.Cloud.beforeSave("Vote", function (request, response) {
    "use strict";
    
    if (!request.object.get("userId")) {
        
        var query = new Parse.Query("Poll").include("createdBy").select(["createdBy"]).get(request.object.get("pollId"), {
            success: function (poll) {
                request.object.set("userId", poll.get("createdBy").id);
                response.success();
            },
            error: function (poll, error) {
                response.error("Get poll" + poll + " error " + error);
            }
        });
    } else {
        response.success();
    }
});

Parse.Cloud.afterSave("Vote", function (request) {
    "use strict";
    
    var query = new Parse.Query(Parse.Installation);
    query.equalTo("userId", request.object.get("userId"));
    
    Parse.Push.send({
        where: query,
        data: {
            alert: "Sua enquete recebeu um voto!",
            badge: "Increment"
        }
    }, {
        success: function () {
            console.log("Push sent");
        },
        error: function (error) {
            console.log("Push error " + error);
        }
    });
});