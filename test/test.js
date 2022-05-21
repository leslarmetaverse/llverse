const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Leslar", function () {
    let leslar;
    let owner;
    let addr1;
    let addr2;
    let addr3;
    let addr4;

    beforeEach(async function() {
        const Leslar = await ethers.getContractFactory("LESLARVERSE");
        leslar = await Leslar.deploy();
        await leslar.deployed();
    
        [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    })

    it("Should be successfully deployed", async function() {
        console.log("Leslar Metaverse deployed to:", leslar.address);
    })

    it("Should be has 1 trillion of supply on owner balance", async function() {
        const decimals = await leslar.decimals();
        const balance = await leslar.balanceOf(owner.address)
        expect(ethers.utils.formatUnits(balance,decimals) == 1000000000000)
    })

    it("Should let you transfer token", async function() {
        const decimals = await leslar.decimals();
        await leslar.transfer(addr1.address, ethers.utils.parseUnits("1000000000", decimals))
        await leslar.transfer(addr1.address, ethers.utils.parseUnits("1000000000", decimals))
        expect(await leslar.balanceOf(addr1.address)).to.equal(ethers.utils.parseUnits("2000000000", decimals))

        await leslar.connect(addr1).approve(addr2.address, ethers.utils.parseUnits("1000000000", decimals))
        await leslar.connect(addr2).transferFrom(addr1.address, addr3.address, ethers.utils.parseUnits("100000", decimals))
        expect(await leslar.balanceOf(addr3.address)).to.equal(ethers.utils.parseUnits("97000.00007275", decimals));
    })

    it("Turn off Reflect Tax", async function() {
        const decimals = await leslar.decimals();
        await leslar.transfer(addr1.address, ethers.utils.parseUnits("1000000000", decimals))
        await leslar.transfer(addr1.address, ethers.utils.parseUnits("1000000000", decimals))
        expect(await leslar.balanceOf(addr1.address)).to.equal(ethers.utils.parseUnits("2000000000", decimals))

        await leslar.setTaxFee(100);
        await leslar.setReflectionFee(0);

        await leslar.connect(addr1).approve(addr2.address, ethers.utils.parseUnits("1000000000", decimals))
        await leslar.connect(addr2).transferFrom(addr1.address, addr3.address, ethers.utils.parseUnits("100000", decimals))
        expect(await leslar.balanceOf(addr3.address)).to.equal(ethers.utils.parseUnits("97000", decimals));
    })

    it("Tax wallet should be receive token with 100% tax fee", async function() {
        const decimals = await leslar.decimals();
        await leslar.transfer(addr1.address, ethers.utils.parseUnits("250000000000", decimals))
        await leslar.transfer(addr1.address, ethers.utils.parseUnits("250000000000", decimals))
        expect(await leslar.balanceOf(addr1.address)).to.equal(ethers.utils.parseUnits("500000000000", decimals))

        await leslar.setBuybackWallet(addr3.address, 33);
        await leslar.setTreasuryWallet(addr3.address, 33);
        await leslar.setMarketingWallet(addr3.address, 34);

        await leslar.setTaxFee(100);
        await leslar.setReflectionFee(0);

        await leslar.connect(addr1).approve(addr2.address, ethers.utils.parseUnits("500000000000", decimals))
        await leslar.connect(addr2).transferFrom(addr1.address, addr4.address, ethers.utils.parseUnits("400000000000", decimals))

        await leslar.triggerTax();
        
        expect(await leslar.balanceOf(addr3.address)).to.equal(ethers.utils.parseUnits("12000000000", decimals));
    })

    it("Tax wallet should be receive token", async function() {
        const decimals = await leslar.decimals();
        await leslar.transfer(addr1.address, ethers.utils.parseUnits("250000000000", decimals))
        await leslar.transfer(addr1.address, ethers.utils.parseUnits("250000000000", decimals))
        expect(await leslar.balanceOf(addr1.address)).to.equal(ethers.utils.parseUnits("500000000000", decimals))

        await leslar.setBuybackWallet(addr3.address, 33);
        await leslar.setTreasuryWallet(addr3.address, 33);
        await leslar.setMarketingWallet(addr3.address, 34);

        await leslar.connect(addr1).approve(addr2.address, ethers.utils.parseUnits("500000000000", decimals))
        await leslar.connect(addr2).transferFrom(addr1.address, addr4.address, ethers.utils.parseUnits("400000000000", decimals))

        await leslar.triggerTax();
        
        expect(await leslar.balanceOf(addr3.address)).to.equal(ethers.utils.parseUnits("9000000000", decimals));
    })

    it("Disable All Fees", async function() {
        const decimals = await leslar.decimals();
        await leslar.transfer(addr1.address, ethers.utils.parseUnits("250000000000", decimals))
        await leslar.transfer(addr1.address, ethers.utils.parseUnits("250000000000", decimals))
        expect(await leslar.balanceOf(addr1.address)).to.equal(ethers.utils.parseUnits("500000000000", decimals))

        await leslar.disableAllFeesTemporarily();

        await leslar.connect(addr1).approve(addr2.address, ethers.utils.parseUnits("500000000000", decimals))
        await leslar.connect(addr2).transferFrom(addr1.address, addr4.address, ethers.utils.parseUnits("400000000000", decimals))
        
        expect(await leslar.balanceOf(addr4.address)).to.equal(ethers.utils.parseUnits("400000000000", decimals));
    })

    it("Disable All Fees and Activate again", async function() {
        const decimals = await leslar.decimals();
        await leslar.transfer(addr1.address, ethers.utils.parseUnits("250000000000", decimals))
        await leslar.transfer(addr1.address, ethers.utils.parseUnits("250000000000", decimals))
        expect(await leslar.balanceOf(addr1.address)).to.equal(ethers.utils.parseUnits("500000000000", decimals))

        await leslar.setBuybackWallet(addr3.address, 33);
        await leslar.setTreasuryWallet(addr3.address, 33);
        await leslar.setMarketingWallet(addr3.address, 34);

        await leslar.disableAllFeesTemporarily();

        await leslar.connect(addr1).approve(addr2.address, ethers.utils.parseUnits("500000000000", decimals))
        await leslar.connect(addr2).transferFrom(addr1.address, addr4.address, ethers.utils.parseUnits("400000000000", decimals))
        
        expect(await leslar.balanceOf(addr4.address)).to.equal(ethers.utils.parseUnits("400000000000", decimals));

        await leslar.restoreAllFees();
        await leslar.connect(addr4).approve(addr4.address, ethers.utils.parseUnits("400000000000", decimals))
        await leslar.connect(addr4).transferFrom(addr4.address, addr1.address, ethers.utils.parseUnits("400000000000", decimals))

        await leslar.triggerTax();

        expect(await leslar.balanceOf(addr3.address)).to.equal(ethers.utils.parseUnits("9000000000", decimals));
    })


    it("Should get charged for sell tax", async function() {
        const decimals = await leslar.decimals();
        await leslar.addAddressToLPs(addr2.address);

        await leslar.transfer(addr1.address, ethers.utils.parseUnits("250000000000", decimals))
        await leslar.transfer(addr1.address, ethers.utils.parseUnits("250000000000", decimals))

        await leslar.setTaxSell(50);

        await leslar.connect(addr1).transfer(addr2.address, ethers.utils.parseUnits("1000000", decimals));

        expect(await leslar.balanceOf(addr2.address)).to.equal(ethers.utils.parseUnits("500000.062500007", decimals));
    })
});
