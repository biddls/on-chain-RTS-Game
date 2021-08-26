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
            // map checks
            expect (await vars.map.nextX()).to.equal(1);
            expect (await vars.map.nextY()).to.equal(0);
            expect (await vars.map.radius()).to.equal(2);

            // nft checks make sure its to the right owner
            expect (await vars.mapNFT.ownerOf(0)).to.equal(vars.owner.address);
            expect (vars.mapNFT.ownerOf(1)).to.be.revertedWith("ERC721: owner query for nonexistent token");

            // map checks to check tile 0
            expect (await (await vars.map.map(0, 0)).ALCX_DAO_NFT_ID).to.equal(
                BigInt('0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'));
        });
    });
});