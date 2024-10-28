const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Voting Contract", function () {
    let Voting;
    let voting;
    let owner;
    let addr1;
    let addr2;

    beforeEach(async function () {
        Voting = await ethers.getContractFactory("Voting");
        [owner, addr1, addr2] = await ethers.getSigners();
        voting = await Voting.deploy();
        await voting.deployed();
    });

    describe("Register Voter", function () {
        it("Should register a voter and emit VoterRegistered event", async function () {
            await expect(voting.registerVoter(addr1.address))
                .to.emit(voting, "VoterRegistered")
                .withArgs(addr1.address);
            const voter = await voting.voters(addr1.address);
            expect(voter.isRegistered).to.equal(true);
        });

        it("Should revert if voter is already registered", async function () {
            await voting.registerVoter(addr1.address);
            await expect(voting.registerVoter(addr1.address)).to.be.revertedWith("Voter is already registered");
        });
    });

    describe("Proposal Registration", function () {
        beforeEach(async function () {
            await voting.registerVoter(addr1.address);
            await voting.startProposalsRegistration();
        });

        it("Should allow a registered voter to register a proposal", async function () {
            await expect(voting.connect(addr1).registerProposal("Proposal 1"))
                .to.emit(voting, "ProposalRegistered")
                .withArgs(0);
            const proposal = await voting.proposals(0);
            expect(proposal.description).to.equal("Proposal 1");
        });

        it("Should revert if proposal registration is not started", async function () {
            await voting.endProposalsRegistration();
            await expect(voting.connect(addr1).registerProposal("Proposal 2")).to.be.revertedWith("This action cannot be performed at this stage");
        });
    });

    describe("Voting", function () {
        beforeEach(async function () {
            await voting.registerVoter(addr1.address);
            await voting.startProposalsRegistration();
            await voting.connect(addr1).registerProposal("Proposal 1");
            await voting.endProposalsRegistration();
            await voting.startVotingSession();
        });

        it("Should allow a registered voter to vote for a proposal", async function () {
            await expect(voting.connect(addr1).vote(0))
                .to.emit(voting, "Voted")
                .withArgs(addr1.address, 0);
            const voter = await voting.voters(addr1.address);
            expect(voter.hasVoted).to.equal(true);
            const proposal = await voting.proposals(0);
            expect(proposal.voteCount).to.equal(1);
        });

        it("Should revert if the voter tries to vote twice", async function () {
            await voting.connect(addr1).vote(0);
            await expect(voting.connect(addr1).vote(0)).to.be.revertedWith("You have already voted");
        });
    });

    describe("Tally Votes", function () {
        beforeEach(async function () {
            await voting.registerVoter(addr1.address);
            await voting.registerVoter(addr2.address);
            await voting.startProposalsRegistration();
            await voting.connect(addr1).registerProposal("Proposal 1");
            await voting.connect(addr2).registerProposal("Proposal 2");
            await voting.endProposalsRegistration();
            await voting.startVotingSession();
            await voting.connect(addr1).vote(0);
            await voting.connect(addr2).vote(1);
            await voting.endVotingSession();
        });

        it("Should correctly tally votes and select a winner", async function () {
            await voting.tallyVotes();
            expect(await voting.winningProposalId()).to.equal(0);
        });

        it("Should revert if trying to tally votes before voting session ends", async function () {
            await voting.startVotingSession();
            await expect(voting.tallyVotes()).to.be.revertedWith("This action cannot be performed at this stage");
        });
    });
});
