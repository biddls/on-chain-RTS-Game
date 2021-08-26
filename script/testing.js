const testing = async function() {
    // setup
    let [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    const balance = await owner.getBalance();

    let contract = await ethers.getContractFactory("ALCX_map");
    const map = await contract.deploy();

    contract = await ethers.getContractFactory("ERC721PresetMinterPauserAutoId");
    const mapNFT = await contract.attach(
        await map.mapNFTAddr()// The deployed contract address
    );

    contract = await ethers.getContractFactory("")

    return {
        map,
        mapNFT,
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