async function main() {
    let contract = await ethers.getContractFactory("ALCX_map");
    const mapCont = await contract.deploy();

    contract = await ethers.getContractFactory("ERC721PresetMinterPauserAutoId");
    const mapNFT = await contract.attach(
        await mapCont.mapNFTAddr()// The deployed contract address
    );

    contract = await ethers.getContractFactory("ERC1155PresetMinterPauser");
    const alcDao = await contract.deploy("");

    mapCont.DAO_nft_TokenChange(alcDao.address);
    console.log('const Map_Addr = "' + await mapCont.address + '"');
    console.log('const MapNFT_Addr = "' + await mapNFT.address + '"');
    console.log('const alcDAO_Addr = "' + await alcDao.address + '"');
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });