const Voting = artifacts.require('Voting')

contract("Voting", accounts => {
    const walter = accounts[0]
    const jessie = accounts[1]
    describe('Walter', () => {
        let v = null
        before(async () => {
            v = await Voting.deployed();
        })
        
        it("has not voted yet", async () => {
            const votes = await v.getTotalVotes("a")
            const expectedVotes = 0
            assert.equal(
                Number(votes),
                Number(expectedVotes),
                "There must be zero votes to start with"
            )
        })

        it("should be able to vote for tabs", async () => {
            await v.vote("tabs")
            const votes = await v.getTotalVotes("tabs")
            const expectedVotes = 1
            assert.equal(
                Number(votes),
                Number(expectedVotes),
                "There must be one vote for tabs"
            )
        })
    })
})