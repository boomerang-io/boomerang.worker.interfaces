const log = require("../log.js");
const fetch = require("node-fetch");
var fs = require("fs");

module.exports = {
  downloadFile(req, inputProps) {
    log.debug("Started Artifactory Download File Plugin");

    fetch(
      "https://tools.boomerangplatform.net/artifactory/boomerang/test/hello",
      {
        method: "GET",
        headers: {
          "X-JFrog-Art-Api":
            "***REMOVED***"
        }
      }
    ).then(res => {
      return new Promise((resolve, reject) => {
        const dest = fs.createWriteStream("file");
        res.body.pipe(dest);
        fs.rename("file", "/data/file", function(err) {
          if (err) throw err;
          console.log("Successfully renamed - AKA moved!");
        });
        res.body.on("error", err => {
          reject(err);
        });
        dest.on("finish", () => {
          resolve();
        });
        dest.on("error", err => {
          reject(err);
        });
      });
    });

    log.debug("Finished Artifactory Download File Plugin");
  },
  uploadFile(req, inputProps) {
    log.debug("Inside Artifactory Upload File Plugin");
  }
};
