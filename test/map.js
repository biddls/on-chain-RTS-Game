const { expect } = require("chai");
const { testing } = require("../script/testing.js");

const zero_address = "0x0000000000000000000000000000000000000000";

function sleep(milliseconds) {
    const start = Date.now();
    while (Date.now() - start < milliseconds);
}

describe("ALCX_map", function () {

    let vars;

    beforeEach(async function () {
        vars = await testing();
    });

    describe("Token contract setup", async function () {
        it("Deployment checks", async function () {
        });
    });
});