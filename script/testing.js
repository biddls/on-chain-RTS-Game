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

    contract = await ethers.getContractFactory("DAO_mint");
    const DAO_mint = await contract.deploy();

    // tells the map where the dao nfts are
    mapCont.DAO_nft_TokenChange(alcDao.address);
    // lets the dao mint contract make nfts for testing
    alcDao.grantRole(alcDao.MINTER_ROLE(), DAO_mint.address);
    // tells the dao mint contract where the dao nfts are
    DAO_mint.changeDAOAddr(alcDao.address);

    return {
        mapCont,
        mapNFT,
        alcDao,
        DAO_mint,
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