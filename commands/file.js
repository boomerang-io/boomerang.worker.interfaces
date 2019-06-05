const log = require("../log.js");
var filePath = require("path");
var fs = require("fs");
const utils = require("../utils.js");

module.exports = {
  createFile() {
    //Create file on file system
    log.debug("Started Create File Plugin");

    const taskProps = utils.substituteTaskInputPropsValuesForWorkflowInputProps();
    log.debug(taskProps);
    const { path, content } = taskProps;

    try {
      fs.writeFile(path + "", content, err => {
        if (err) {
          log.err(err);
          throw err;
        }
        log.debug("The file was succesfully saved!");
      });
    } catch (e) {
      log.err(e);
      process.exit(1);
    }

    log.debug("Finished Create File Plugin");
  },
  readFileToProperty() {
    //Read in a file and set contents as an output property
    log.debug("Started Read File to Property Plugin");

    const taskProps = utils.substituteTaskInputPropsValuesForWorkflowInputProps();
    const { path: path, propertyName: propertyName } = taskProps;
    try {
      const file = fs.readFileSync(path, "utf8");
      utils.setOutputProperty(propertyName, file);
      log.debug("The file was succesfully read!");
    } catch (e) {
      log.err(e);
      process.exit(1);
    }

    log.debug("Finished Read File to Property Plugin");
  },
  readPropertiesFromFile() {
    //Read in a file of type properties file and parse every property (based on a delimiter, default being '=') and set as output properties.
    log.debug("Started Read Properties From File Plugin");

    const taskProps = utils.substituteTaskInputPropsValuesForWorkflowInputProps();
    const { path, delimiter = "=" } = taskProps;
    const delimiterExpression = new RegExp(`${delimiter}(.+)`);

    try {
      const file = fs.readFileSync(path, "utf-8");

      const fileArray = file.split("\r\n");
      let fileObject = {};

      fileArray.forEach(file => {
        let fileData = file.split(delimiterExpression);
        fileObject[fileData[0]] = fileData[1];
      });
      utils.setOutputProperties(fileObject);
      log.good("The file was succesfully read!");
    } catch (e) {
      log.err(e);
      process.exit(1);
    }

    log.debug("Finished Read Properties From File Plugin");
  },
  checkFileOrFolderExists() {
    //Return true if file or folder exists based on regular expression
    log.debug("Started Check File or Folder Exists Plugin");

    const taskProps = utils.substituteTaskInputPropsValuesForWorkflowInputProps();
    const { path, expression } = taskProps;
    //Used to check if the path indicates a file or a directory
    const fileExtension = filePath.extname(path);
    try {
      //Search for files and directories that match the expression inside the path dir
      if (expression && !fileExtension) {
        const regExp = new RegExp(expression);
        fs.readdir(path, (err, files) => {
          let filteredFiles = files.filter(file => {
            return regExp.test(file);
          });
          if (filteredFiles.length === 0)
            throw new Error("Regex expression doesn't match any file.");
        });
      } else {
        fs.stat(path, (err, stat) => {
          if (!stat) throw new Error("File not found.");
        });
      }
      log.good("The file/directory was found!");
    } catch (e) {
      log.err(e);
      process.exit(1);
    }
    log.debug("Finished Check File or Folder Exists Plugin");
  },
  checkFileContainsString() {
    // Check if a file contains string or matches regular expression
    log.debug("Started Check File Contains String Plugin");

    const taskProps = utils.substituteTaskInputPropsValuesForWorkflowInputProps();
    const { path, expression, flags, string } = taskProps;

    try {
      const file = fs.readFileSync(path, "utf-8");
      let result;

      if (expression) {
        const fileExpression = new RegExp(
          expression,
          flags ? flags : undefined
        );
        result = fileExpression.test(file);
      } else {
        result = file.includes(string);
      }

      if (result) {
        log.good(
          expression ? "Regex expression matched." : "String found in file."
        );
      } else {
        throw new Error(
          expression ? "Regex expression didn't match." : "String not found."
        );
      }
    } catch (e) {
      log.err(e);
      process.exit(1);
    }

    log.debug("Finished Check File Contains String Plugin");
  },
  replaceStringInFile() {
    // Replace string in file finding by string or regular expression
    log.debug("Started Replace String In File Plugin");

    const taskProps = utils.substituteTaskInputPropsValuesForWorkflowInputProps();
    const { path, expression, flags, findString, replaceString } = taskProps;

    try {
      const file = fs.readFileSync(path, "utf-8");
      let result;

      if (expression) {
        const fileExpression = new RegExp(
          expression,
          flags ? flags : undefined
        );
        if (!fileExpression.test(file))
          throw new Error("Regex expression didn't match.");
        result = file.replace(fileExpression, replaceString);
      } else {
        if (!file.includes(findString)) throw new Error("String not found.");
        result = file.replace(findString, replaceString);
      }

      fs.writeFileSync(path, result, "utf-8");
      log.good("The string has been replaced!");
    } catch (e) {
      log.err(e);
      process.exit(1);
    }

    log.debug("Finished Replace String In File Plugin");
  }
};
