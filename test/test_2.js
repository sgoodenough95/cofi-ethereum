/* global ethers */

const { getSelectors, FacetCutAction } = require('../scripts/libraries/diamond.js')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { diamondAbi } = require('./Stoa-Diamond.json')
const { ethers } = require('hardhat')
const MAX_UINT = '115792089237316195423570985008687907853269984665640564039457584007913129639935'

describe('First test', function() {

    async function deployToken () {

        const accounts = await ethers.getSigners()
        const alice = accounts[0]
        const bob = accounts[1]
    
        // deploy Stoa Active Dollar
        const StoaActiveDollar = await ethers.getContractFactory('ActiveToken')
        const USDST = await StoaActiveDollar.deploy('Stoa Active Dollar', 'USDST')
        await USDST.deployed()
        console.log('Stoa Active Dollar deployed:', USDST.address)

        return { alice, bob, USDST }
    }

    it('Should track yield earned', async function() {

        const { alice, bob, USDST } = await loadFixture(deployToken)

        // Mint 10,000 tokens to user.
        await USDST.mint(alice.address, '10000000000000000000000')

        console.log('T0 Yield earned: ' + await USDST.getYieldEarned(alice.address))

        await USDST.changeSupply('11000000000000000000000')

        console.log('T1 Yield earned: ' + await USDST.getYieldEarned(alice.address))

        await USDST.transfer(bob.address, '1000000000000000000000')

        console.log('T2 Alice yield earned: ' + await USDST.getYieldEarned(alice.address))
        console.log('T2 Bob yield earned: ' + await USDST.getYieldEarned(bob.address))

        await USDST.changeSupply('12000000000000000000000')

        console.log('T3 Alice yield earned: ' + await USDST.getYieldEarned(alice.address))
        console.log('T3 Bob yield earned: ' + await USDST.getYieldEarned(bob.address))

        await USDST.burn(alice.address, '1000000000000000000000')
        await USDST.burn(bob.address, '1000000000000000000000')

        console.log('T4 Alice yield earned: ' + await USDST.getYieldEarned(alice.address))
        console.log('T4 Bob yield earned: ' + await USDST.getYieldEarned(bob.address))
    })
})