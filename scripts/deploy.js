async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const NFTLottery = await ethers.getContractFactory("NFTLottery");
  const nftLottery = await NFTLottery.deploy({ gasLimit: 4000000});

  console.log("Lottery address:", nftLottery.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
