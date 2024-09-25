const VotingContract = artifacts.require('VotingContract.sol')


module.exports = async (deployer) => {
    try {
        await deployer.deploy(VotingContract)
    } catch (error) {
        console.log("error messsage  : ",error)
    }
}