// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Voting
 * @dev A contract for voting on proposals.
 */
contract Voting {
    enum VoteStates {Absent, Yes, No}
    uint constant VOTE_THRESHOLD = 10;

    struct Proposal {
        address target; // The address of the contract to be called if the proposal is approved
        bytes data; // The data to be sent when calling the contract
        bool executed; // A flag to indicate if the proposal has already been executed
        uint yesCount; // The number of "yes" votes
        uint noCount; // The number of "no" votes
        mapping (address => VoteStates) voteStates; // A mapping of addresses to their vote state (yes, no, or absent)
    }

    Proposal[] public proposals; // An array of all proposals

    event ProposalCreated(uint); // An event emitted when a new proposal is created
    event VoteCast(uint, address indexed); // An event emitted when a vote is cast

    mapping(address => bool) members; // A mapping of addresses to a boolean indicating membership

    /**
     * @dev Constructor function for the Voting contract.
     * @param _members An array of addresses representing the members of the voting group.
     */
    constructor(address[] memory _members) {
        for(uint i = 0; i < _members.length; i++) {
            members[_members[i]] = true; // Add each member to the membership mapping
        }
        members[msg.sender] = true; // Add the contract creator to the membership mapping
    }

    /**
     * @dev Create a new proposal.
     * @param _target The address of the contract to be called if the proposal is approved.
     * @param _data The data to be sent when calling the contract.
     */
    function newProposal(address _target, bytes calldata _data) external {
        require(members[msg.sender]); // Only members can create proposals
        emit ProposalCreated(proposals.length); // Emit a ProposalCreated event
        Proposal storage proposal = proposals.push(); // Create a new proposal and add it to the proposals array
        proposal.target = _target; // Set the target of the proposal
        proposal.data = _data; // Set the data of the proposal
    }

    /**
     * @dev Cast a vote for a proposal.
     * @param _proposalId The index of the proposal in the proposals array.
     * @param _supports A boolean indicating whether the voter supports the proposal.
     */
    function castVote(uint _proposalId, bool _supports) external {
        require(members[msg.sender]); // Only members can cast votes
        Proposal storage proposal = proposals[_proposalId]; // Get the proposal being voted on

        // Clear out previous vote
        if(proposal.voteStates[msg.sender] == VoteStates.Yes) {
            proposal.yesCount--; // Decrement the "yes" vote count
        }
        if(proposal.voteStates[msg.sender] == VoteStates.No) {
            proposal.noCount--; // Decrement the "no" vote count
        }

        // Add new vote
        if(_supports) {
            proposal.yesCount++; // Increment the "yes" vote count
        }
        else {
            proposal.noCount++; // Increment the "no" vote count
        }

        // Record the new vote and its state
        proposal.voteStates[msg.sender] = _supports ? VoteStates.Yes : VoteStates.No;

        emit VoteCast(_proposalId, msg.sender); // Emit a VoteCast event

        // If the proposal has received enough "yes" votes and has not already been executed, execute it
        if(proposal.yesCount == VOTE_THRESHOLD && !proposal.executed) {
        (bool success, ) = proposal.target.call(proposal.data);
        require(success, "Failed to execute proposal"); // Require that the proposal is executed successfully
        proposal.executed = true; // Mark the proposal as executed
    }
}