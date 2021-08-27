const testing = async function() {
    // setup
    let [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    const balance = await owner.getBalance();

    let contract = await ethers.getContractFactory("ALCX_map");
    const mapCont = await contract.deploy();



    contract = await ethers.getContractFactory("ERC721PresetMinterPauserAutoId");
    const mapNFT = await contract.attach(
        await mapCont.mapNFTAddr()// The deployed contract address
    );

    contract = await ethers.getContractFactory("ERC1155PresetMinterPauser");
    const alcDao = await contract.deploy("");

    mapCont.DAO_nft_TokenChange(alcDao.address);

    return {
        mapCont,
        mapNFT,
        alcDao,
        balance,
        owner,
        addr1,
        addr2,
        addr3,
        addrs
    };
}

module.exports = {
    testing
}