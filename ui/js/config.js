var Config = function() {
    var serverName = "localhost";
    var port = "8100";

    function getUrl() {
        return window.location.protocol + "//" + serverName + ":" + port;
    }
    return {
        getUrl: getUrl
    }
};
