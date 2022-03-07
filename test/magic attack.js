const { expect } = require("chai");
const { testing } = require("../script/testing.js");

const zero_address = "0x0000000000000000000000000000000000000000";
const max_numb = BigInt("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
const max_address = "0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF";

function sleep(milliseconds) {
    const start = Date.now();
    while (Date.now() - start < milliseconds);
}

describe("magic attack", function () {

    let vars;

    beforeEach(async function () {
        vars = await testing();
    });

    describe("Token contract setup", async function () {
        it("deployment checks", async function () {
            // map nft checks
            expect( await vars.mapCont.mapNFTsAddr()).to.equal(vars.mapNFT.address);

            // map checks
            expect (await vars.mapCont.nextX()).to.equal(1);
            expect (await vars.mapCont.nextY()).to.equal(0);
            expect (await vars.mapCont.radius()).to.equal(2);

            // nft checks make sure its to the right owner
            expect (await vars.mapNFT.ownerOf(0)).to.equal(vars.owner.address);
            expect (vars.mapNFT.ownerOf(1)).to.be.revertedWith("ERC721: owner query for nonexistent token");

            // map checks to check tile 0
            expect (await (await vars.mapCont.map(0, 0)).ALCX_DAO_NFT_ID).to.equal(max_numb);

            // dao nft whos the admin
            expect (await vars.alcDao.getRoleMember(await vars.alcDao.DEFAULT_ADMIN_ROLE(), 0)).
            to.equal(vars.owner.address);
        });
    });
    describe("map reinforcement", async function () {
        it("", async function () {
            await vars.alcDao.mint(vars.owner.address, 0, 10, "0x");
            await vars.alcDao.mint(vars.owner.address, 1, 10, "0x");
            await vars.alcDao.setApprovalForAll(vars.mapCont.address, true);

            await vars.mapCont.redeemNFTsForLand([0, 1],[1, 2]);

            // increaseLandsProtection
            await vars.magic_attack.increaseLandsProtection(1, 0, 2);
            expect (await (await vars.mapCont.map(1, 0)).NFTProtection).to.equal(2);

            // decreaseLandsProtection
            await vars.magic_attack.decreaseLandsProtection(1, 0, 1);
            expect (await (await vars.mapCont.map(1, 0)).NFTProtection).to.equal(1);
            await vars.magic_attack.decreaseLandsProtection(1, 0, 1);
            expect (await (await vars.mapCont.map(1, 0)).NFTProtection).to.equal(0);
            expect (vars.magic_attack.decreaseLandsProtection(1, 0, 1))
                .to.be.revertedWith("Not enough NFTs on tile");
        });
    });
    describe("magic attack", async function () {
        it("basic map", async function () {
            await vars.alcDao.mint(vars.owner.address, 0, 10, "0x");
            await vars.alcDao.mint(vars.addr1.address, 0, 10, "0x");
            await vars.alcDao.setApprovalForAll(vars.mapCont.address, true);
            await vars.alcDao.connect(vars.addr1).setApprovalForAll(vars.mapCont.address, true);

            await vars.mapCont.redeemNFTsForLand([0],[1]);
            await vars.mapCont.connect(vars.addr1).redeemNFTsForLand([0],[1]);

            // increaseLandsProtection
            await vars.magic_attack.increaseLandsProtection(1, 0, 2);
            expect (await (await vars.mapCont.map(1, 0)).NFTProtection).to.equal(2);

            await vars.magic_attack.connect(vars.addr1).increaseLandsProtection(1, 1, 3);
            expect (await (await vars.mapCont.map(1, 1)).NFTProtection).to.equal(3);

            // magic attack and fail
            await vars.magic_attack.magicAttack(1, 1, 1, 0, 2);
            expect (await (await vars.mapCont.map(1, 1)).NFTProtection).to.equal(1);

            // magic attack and kill
            await vars.magic_attack.magicAttack(1, 1, 1, 0, 2);
            expect (await (await vars.mapCont.map(1, 1)).NFTProtection).to.equal(0);
            expect (await (await vars.mapCont.map(1, 1)).dead).to.be.true;
        });
        it("complex map", async function () {
            await vars.alcDao.mint(vars.owner.address, 0, 10, "0x");
            await vars.alcDao.mint(vars.addr1.address, 0, 10, "0x");
            await vars.alcDao.setApprovalForAll(vars.mapCont.address, true);
            await vars.alcDao.connect(vars.addr1).setApprovalForAll(vars.mapCont.address, true);

            await vars.mapCont.redeemNFTsForLand([0],[4]);
            await vars.mapCont.connect(vars.addr1).redeemNFTsForLand([0], [4]);

            await vars.magic_attack.magicAttack(0, 2, 0, 1, 1);
            await vars.magic_attack.magicAttack(1, 2, 0, 1, 1);
            await vars.magic_attack.magicAttack(2, 1, 2, 0, 1);

            await expect(vars.magic_attack.connect(vars.addr1).magicAttack(2, 2, 1, 1, 1)).to.be.reverted;
        });
        it("EdGe CaSeS...", async function () {
            await vars.alcDao.mint(vars.owner.address, 0, 8, "0x");
            await vars.alcDao.mint(vars.addr1.address, 0, 8, "0x");
            await vars.alcDao.setApprovalForAll(vars.mapCont.address, true);
            await vars.alcDao.connect(vars.addr1).setApprovalForAll(vars.mapCont.address, true);

            await vars.mapCont.connect(vars.addr1).redeemNFTsForLand([0],[1]);
            await vars.mapCont.redeemNFTsForLand([0],[1]);
            await vars.mapCont.connect(vars.addr1).redeemNFTsForLand([0],[2]);
            await vars.mapCont.redeemNFTsForLand([0],[3]);
            await vars.mapCont.connect(vars.addr1).redeemNFTsForLand([0],[1]);

            await vars.magic_attack.magicAttack(0, 2, 1, 2, 1);
            await vars.magic_attack.magicAttack(0, 1, 1, 1, 1);
            await vars.magic_attack.magicAttack(1, 0, 1, 1, 1);
            await vars.magic_attack.magicAttack(2, 0, 1, 1, 1);
            await expect (vars.magic_attack.magicAttack(0, 0, 1, 1, 1)).to.be.reverted;
            await expect (vars.magic_attack.connect(vars.addr1).magicAttack(1, 1, 0, 0, 1)).to.be.reverted;
        });
    });
});