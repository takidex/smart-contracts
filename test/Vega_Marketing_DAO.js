const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

describe("Vega_Marketing_DAO", function () {
  async function deployVegaMarketingDAO() {
    const [owner, otherAccount] = await ethers.getSigners();
    const VMD = await ethers.getContractFactory("VMD");
    const USDT_Test = await ethers.getContractFactory("USDT_Test");
    const Vega_Marketing_DAO = await ethers.getContractFactory("Vega_Marketing_DAO");
    const vmd = await VMD.deploy("VMD Token", "VMD");
    const usdt = await USDT_Test.deploy("Tether", "USDT");
    const vegaMarketingDAO = await Vega_Marketing_DAO.deploy(usdt.target, vmd.target);
    await vmd.transferOwnership(vegaMarketingDAO.target);
    expect(await (usdt.decimals())).to.be.equal(6);
    return { vmd, usdt, vegaMarketingDAO, owner, otherAccount };
  }
  it("Should buy tokens", async function () {
    const { vmd, usdt, vegaMarketingDAO, owner, otherAccount } = await loadFixture(deployVegaMarketingDAO);
    await usdt.approve(vegaMarketingDAO.target, 1_000_000 * 1e6);
    let vmdBalance = Number(ethers.formatEther((await vmd.balanceOf(owner)).toString()));
    let usdtBalance = (await usdt.balanceOf(vegaMarketingDAO.target));
    expect(vmdBalance).to.be.equal(0);
    expect(usdtBalance).to.be.equal(0);
    await vegaMarketingDAO.buyTokens(1_000 * 1e6);
    vmdBalance = Number(ethers.formatEther((await vmd.balanceOf(owner)).toString()));
    usdtBalance = (await usdt.balanceOf(vegaMarketingDAO.target));
    expect(vmdBalance).to.be.equal(1_000 * 200);
    expect(usdtBalance).to.be.equal(1_000 * 1e6);
    await vegaMarketingDAO.buyTokens(99_000 * 1e6);
    vmdBalance = Number(ethers.formatEther((await vmd.balanceOf(owner)).toString()));
    usdtBalance = (await usdt.balanceOf(vegaMarketingDAO.target));
    expect(vmdBalance).to.be.equal(100_000 * 200);
    expect(usdtBalance).to.be.equal(100_000 * 1e6);
    await vegaMarketingDAO.buyTokens(499_000 * 1e6);
    vmdBalance = Number(ethers.formatEther((await vmd.balanceOf(owner)).toString()));
    usdtBalance = (await usdt.balanceOf(vegaMarketingDAO.target));
    expect(vmdBalance).to.be.equal((100_000 * 200) + (499_000 * 100));
    expect(usdtBalance).to.be.equal(599_000 * 1e6);
    await expect(vegaMarketingDAO.buyTokens(1_001 * 1e6)).to.be.revertedWith("Tokens sold out");
    vmdBalance = Number(ethers.formatEther((await vmd.balanceOf(owner)).toString()));
    usdtBalance = (await usdt.balanceOf(vegaMarketingDAO.target));
    expect(vmdBalance).to.be.equal((100_000 * 200) + (499_000 * 100));
    expect(usdtBalance).to.be.equal(599_000 * 1e6);
  });
  it("Should transfer ownership", async function() {
    const { vmd, usdt, vegaMarketingDAO, owner, otherAccount } = await loadFixture(deployVegaMarketingDAO);
    expect(await vmd.owner()).to.be.equal(vegaMarketingDAO.target);
    await vegaMarketingDAO.transferVmdOwnership(otherAccount);
    expect(await vmd.owner()).to.be.equal(otherAccount);
    await expect(vegaMarketingDAO.connect(otherAccount).transferVmdOwnership(owner)).to.be.reverted;
  });
  it('Should withdraw ERC20 token', async function() {
    const { vmd, usdt, vegaMarketingDAO, owner, otherAccount } = await loadFixture(deployVegaMarketingDAO);
    let usdtBalance = (await usdt.balanceOf(vegaMarketingDAO.target));
    expect(usdtBalance).to.be.equal(0);
    await vegaMarketingDAO.withdrawErc20(usdt.target);
    await usdt.approve(vegaMarketingDAO.target, 1_000_000 * 1e6);
    await vegaMarketingDAO.buyTokens(1_000 * 1e6);
    usdtBalance = (await usdt.balanceOf(vegaMarketingDAO.target));
    expect(usdtBalance).to.be.equal(1_000 * 1e6);
    await vegaMarketingDAO.withdrawErc20(usdt.target);
    usdtBalance = usdtBalance = (await usdt.balanceOf(vegaMarketingDAO.target));
    expect(usdtBalance).to.be.equal(0);
    await expect(vegaMarketingDAO.connect(otherAccount).withdrawErc20(usdt.target)).to.be.reverted;
  });
});