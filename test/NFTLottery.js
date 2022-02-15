const { expect } = require("chai");

describe("NFTLottery contract", function () {
  it("shouldn't be able to bid on an inactive auction", async function () {
    const [owner] = await ethers.getSigners();
    const NFTLottery = await ethers.getContractFactory("NFTLottery");

    const lotteryContract = await NFTLottery.deploy();

    await expect(
      lotteryContract.bid({ value: ethers.utils.parseEther("0.01") })
    ).to.be.revertedWith("Auction must be active");
  });
  it("should start a new auction and emit NewAuction", async function () {
    const [owner] = await ethers.getSigners();
    const NFTLottery = await ethers.getContractFactory("NFTLottery");

    const lotteryContract = await NFTLottery.deploy();

    await expect(lotteryContract.startNewAuction(ethers.utils.parseEther("0.01")))
    .to.emit(lotteryContract, 'NewAuction')
    .withArgs(1, ethers.utils.parseEther("0.01"));
  });
  it("should be able to bid on active auction, increase bidders count, and emit Bid event", async function () {
    const [owner] = await ethers.getSigners();
    const NFTLottery = await ethers.getContractFactory("NFTLottery");

    const lotteryContract = await NFTLottery.deploy();
    await lotteryContract.startNewAuction(ethers.utils.parseEther("0.01"));

    await expect(lotteryContract.bid({ value: ethers.utils.parseEther("0.01") }))
    .to.emit(lotteryContract, 'Bid')
    .withArgs(owner.address, 1, ethers.utils.parseEther("0.01"), 1);
  });
  it("should draw a winner and award NFT", async function () {
    const [owner] = await ethers.getSigners();
    const NFTLottery = await ethers.getContractFactory("NFTLottery");

    const lotteryContract = await NFTLottery.deploy();
    await lotteryContract.startNewAuction(ethers.utils.parseEther("0.01"));
    await lotteryContract.bid({ value: ethers.utils.parseEther("0.01") });

    await expect(lotteryContract.drawWinner())
    .to.emit(lotteryContract, 'Reward')
    .withArgs(owner.address, 1, 1);
  });
  it("should withdraw bid from previous auction", async function () {
    const [owner] = await ethers.getSigners();
    const NFTLottery = await ethers.getContractFactory("NFTLottery");

    const lotteryContract = await NFTLottery.deploy();
    await lotteryContract.startNewAuction(ethers.utils.parseEther("0.01"));
    await lotteryContract.bid({ value: ethers.utils.parseEther("0.01") });
    await lotteryContract.drawWinner();

    await expect(lotteryContract.withdraw(1))
    .to.emit(lotteryContract, 'Withdraw')
    .withArgs(owner.address, 1, ethers.utils.parseEther("0.01"));
  });
  // test withdrawing
});
