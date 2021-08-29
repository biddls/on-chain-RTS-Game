const { expect } = require("chai");
const { testing } = require("../script/testing.js");

const zero_address = "0x0000000000000000000000000000000000000000";
const max_numb = BigInt("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
const max_address = "0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF";

function sleep(milliseconds) {
    const start = Date.now();
    while (Date.now() - start < milliseconds);
}

describe("DAO_mint", function () {

    let vars;

    beforeEach(async function () {
        vars = await testing();
    });

    describe("Token contract setup", async function () {
        it("deployment checks", async function () {

        });
    });
});