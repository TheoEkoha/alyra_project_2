// SPDX-License-Identifier: MIT
// Théo Olivieri - Pato

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
   constructor() Ownable(msg.sender) {}
   
   struct Voter {
      bool isRegistered;
      bool hasVoted;
      uint votedProposalId;
   }

   struct Proposal {
      string description;
      uint voteCount;
   }

   enum WorkflowStatus {
      RegisteringVoters,
      ProposalsRegistrationStarted,
      ProposalsRegistrationEnded,
      VotingSessionStarted,
      VotingSessionEnded,
      VotesTallied
   }

   WorkflowStatus public status;
   Proposal[] public proposals;
   mapping(address => Voter) public voters;
   uint public winningProposalId;

   event VoterRegistered(address voterAddress);
   event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
   event ProposalRegistered(uint proposalId);
   event Voted(address voter, uint proposalId);

   modifier onlyRegisteredVoters() {
      require(voters[msg.sender].isRegistered, "You are not a registered voter");
      _;
   }

   modifier atStatus(WorkflowStatus _status) {
      require(status == _status, "This action cannot be performed at this stage");
      _;
   }

   function registerVoter(address _voter) external onlyOwner atStatus(WorkflowStatus.RegisteringVoters) {
      require(!voters[_voter].isRegistered, "Voter is already registered");
      voters[_voter].isRegistered = true;
      emit VoterRegistered(_voter);
   }

   function startProposalsRegistration() external onlyOwner atStatus(WorkflowStatus.RegisteringVoters) {
      status = WorkflowStatus.ProposalsRegistrationStarted;
      emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
   }

   function registerProposal(string memory _description) external onlyRegisteredVoters atStatus(WorkflowStatus.ProposalsRegistrationStarted) {
      proposals.push(Proposal({
         description: _description,
         voteCount: 0
      }));
      emit ProposalRegistered(proposals.length - 1);
   }

   function endProposalsRegistration() external onlyOwner atStatus(WorkflowStatus.ProposalsRegistrationStarted) {
      status = WorkflowStatus.ProposalsRegistrationEnded;
      emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
   }

   function startVotingSession() external onlyOwner atStatus(WorkflowStatus.ProposalsRegistrationEnded) {
      status = WorkflowStatus.VotingSessionStarted;
      emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
   }

   function vote(uint _proposalId) external onlyRegisteredVoters atStatus(WorkflowStatus.VotingSessionStarted) {
      Voter storage sender = voters[msg.sender];
      require(!sender.hasVoted, "You have already voted");
      require(_proposalId < proposals.length, "Invalid proposal ID");

      sender.hasVoted = true;
      sender.votedProposalId = _proposalId;
      proposals[_proposalId].voteCount += 1;
      emit Voted(msg.sender, _proposalId);
   }

   function endVotingSession() external onlyOwner atStatus(WorkflowStatus.VotingSessionStarted) {
      status = WorkflowStatus.VotingSessionEnded;
      emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
   }

   function tallyVotes() external onlyOwner atStatus(WorkflowStatus.VotingSessionEnded) {
      uint winningVoteCount = 0;

      for (uint i = 0; i < proposals.length; i++) {
         if (proposals[i].voteCount > winningVoteCount) {
               winningVoteCount = proposals[i].voteCount;
               winningProposalId = i;
         }
      }

      status = WorkflowStatus.VotesTallied;
      emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
   }

   function getWinner() external view atStatus(WorkflowStatus.VotesTallied) returns (string memory) {
      return proposals[winningProposalId].description;
   }
}