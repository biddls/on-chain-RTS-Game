async function main() {

    let contract = await ethers.getContractFactory("Chebyshev_math");
    const Chebyshev_math = await contract.deploy();

    // contract = await ethers.getContractFactory("mapChecks");
    // const mapChecks = await contract.deploy();

    contract = await ethers.getContractFactory("ALCX_map");
    const mapCont = await contract.deploy();

    contract = await ethers.getContractFactory("Magic_attack", {
        libraries: {
            Chebyshev_math: Chebyshev_math.address,
        },
    });
    const magic_attack = await contract.deploy();

    contract = await ethers.getContractFactory("ERC721PresetMinterPauserAutoId");
    const mapNFT = await contract.attach(
        await mapCont.mapNFTAddr()// The deployed contract address
    );

    contract = await ethers.getContractFactory("ERC1155PresetMinterPauser");
    const alcDao = await contract.deploy("");

    contract = await ethers.getContractFactory("DAO_mint");
    const DAO_mint = await contract.deploy();

    // tells the map where the dao nfts are
    await mapCont.DAO_nft_TokenChange(alcDao.address);
    // lets the dao mint contract make nfts for testing
    await alcDao.grantRole(alcDao.MINTER_ROLE(), DAO_mint.address);
    // tells the dao mint contract where the dao nfts are
    await DAO_mint.changeDAOAddr(alcDao.address);
    // tells the magic attack contract where the map and map nft contracts are
    await magic_attack.updateAddresses(mapCont.address, mapNFT.address);
    // gives permissions
    await mapCont.map_control_roll_control(true, magic_attack.address);

    console.log('const Map_Addr = "' + await mapCont.address + '"');
    console.log('const Magic_attack_Addr = "' + await magic_attack.address + '"');
    console.log('const MapNFT_Addr = "' + await mapNFT.address + '"');
    console.log('const alcDAO_Addr = "' + await alcDao.address + '"');
    console.log('const DAO_mint_Addr = "' + await DAO_mint.address + '"');
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });