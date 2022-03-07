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
            expect (await vars.DAO_mint.admin()).to.equal(vars.owner.address);
            expect (await vars.alcDao.hasRole(
                vars.alcDao.MINTER_ROLE(), vars.DAO_mint.address))
                .to.be.true;
        });
    });
    describe("dao nft minting", async function () {
        it("normal", async function () {
            expect (await vars.alcDao.hasRole(
                vars.alcDao.MINTER_ROLE(), vars.DAO_mint.address))
                .to.be.true;
            await vars.DAO_mint.getNFTs([0,1,2,3,4], [2,2,2,2,2], "0x");
        });
        it("break it", async function () {
            expect (await vars.alcDao.hasRole(
                vars.alcDao.MINTER_ROLE(), vars.DAO_mint.address))
                .to.be.true;
            await expect( vars.DAO_mint.getNFTs([0,1,2,3,4,4], [2,2,2,2,2], "0x")).to.be.reverted;
            await expect( vars.DAO_mint.getNFTs([0,1,2,3,4,4], [2,2,2,2,2,2], "0x")).to.be.reverted;
            await expect( vars.DAO_mint.getNFTs([0,1,2,3,4], [10,2,2,2,2], "0x")).to.be.reverted;
            await expect( vars.DAO_mint.getNFTs([5], [10], "0x")).to.be.reverted;
        })
    });
});