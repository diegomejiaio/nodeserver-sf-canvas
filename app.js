var express = require("express"),
  bodyParser = require("body-parser"),
  path = require("path");
var app = express();
var crypto = require("crypto");
var consumerSecretApp = process.env.CANVAS_CONSUMER_SECRET;


console.log("consumer secret - " + consumerSecretApp);

app.use(express.static(path.join(__dirname, "views")));
app.set("view engine", "ejs");

app.use(bodyParser.urlencoded());

app.use(bodyParser.json());

app.get("/", function (req, res) {
  res.render("hello");
});

app.post("/", function (req, res) {
  // console.log("req.body", req.body);
  // console.log("req.body.signed_request", req.body.signed_request);
  // console.log("req.body.signed_request.length", req.body.signed_request.length);
  // console.log("req.body.signed_request[0]", req.body.signed_request[0]);
  // console.log("req.body.signed_request[1]", req.body.signed_request[1]);
  var bodyArray = req.body.signed_request.split(".");
  // console.log("bodyArray", bodyArray);
  var consumerSecret = bodyArray[0];
  // console.log("consumerSecret", consumerSecret);
  var encoded_envelope = bodyArray[1];
  // console.log("encoded_envelope", encoded_envelope);

  var check = crypto
    .createHmac("sha256", consumerSecretApp)
    .update(encoded_envelope)
    .digest("base64");

  // console.log("check", check);

  if (check === consumerSecret) {
    var envelope = JSON.parse(new Buffer(encoded_envelope, "base64").toString("ascii"));
    //req.session.salesforce = envelope;
    // console.log("got the session object:");
    // console.log(envelope);
    // console.log(JSON.stringify(envelope));
    res.render("index", {
      title: envelope.context.user.userName,
      req: JSON.stringify(envelope).replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;'),
      // Add user data from the envelope
      userId: envelope.context.user.userId,
      userName: envelope.context.user.userName,
      userEmail: envelope.context.user.email,
      userProfile: envelope.context.user.fullName,
      userProfileId: envelope.context.user.profileId,
      userOrgId: envelope.context.organization.organizationId,
      userOrgName: envelope.context.organization.name
    });
  } else {
    console.log("authentication failed");
    console.log("check", check);
    console.log("consumerSecretApp", consumerSecretApp);
    console.log("consumerSecret", consumerSecret);
    console.log("encoded_envelope", encoded_envelope);
    // Lest add logs in the response
    res.send(
      "Authentication failed. Check the logs for more details. <br> check: " +
      check +
      "<br> consumerSecretApp: " +
      consumerSecretApp +
      "<br> consumerSecret: " +
      consumerSecret +
      "<br> encoded_envelope: " +
      encoded_envelope
    );
  }
});

const port = process.env.PORT || 3000;
app.listen(port, function () {
  console.log(`server is listening on port ${port}!!!`);
});
