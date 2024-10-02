var Config = function() {
    var serverName = "localhost";
    var port = "8103";

    function getUrl() {
        return window.location.protocol + "//" + serverName + ":" + port;
    }
    return {
        getUrl: getUrl
    }
};
