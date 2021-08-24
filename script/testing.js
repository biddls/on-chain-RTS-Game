const testing = async function() {
    // setup
    let [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    const balance = await owner.getBalance();

    let contract = await ethers.getContractFactory("ALCX_map");
    const map = await contract.deploy();

    return {
        map,
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