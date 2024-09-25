// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract VotingContract {
    uint256 public proposalCount;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    using SafeMath for uint256;

    /// @notice Detailed feilds of proposal
    struct Proposal {
        //  proposal Id
        uint256 id;
        //  owner of the proposal
        address proposer;
        //  favor votes of the proposal
        uint256 favorVotes;
        //  against votes of the proposal
        uint256 againstVotes;
        //  canceled = true if the proposal if cancelled
        bool canceled;
        //  announced = true if the proposal if announced
        bool announced;
        // total No.of voters
        uint256 voterCount;
        // description  of the proposal
        string description;
        // title  of the proposal
        string title;
        // proposal created Date
        uint256 dateOfCreation;
        // deadLine of the proposal for vote
        uint256 deadLine;
        // set the proposal is passed or rejected status by Enum
        ProposalState res;
    }
    /// @notice receipt record for a voters
    struct VoteReceipt {
        //  Whether Voted or Not
        bool isVoted;
        //  whether vote for favor or against
        bool isSupport;
        //  Vote Count
        uint256 votes;
    }

     struct Vote {
        address voterAddress;
        bool support;
        uint256 votes;
    }

    // The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;

    // To store receipts of all voters on all proposals
    // proposalId => (voterAddress => VoteReceipt)
    mapping(uint256 => mapping(address => VoteReceipt)) receipts;

    // To store all voters on all proposals
    // proposalId => (voterIndex => voterAddress)
    mapping(uint256 => mapping(uint256 => address)) voters;

    /// @notice Possible states that a proposal may be in
    enum ProposalState {ACTIVE, CANCELED, ACCEPTED, REJECTED}

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated( uint256 id, address proposer, string description, string title, uint256 dateOfCreation);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint256 proposalId, bool support);

    function createProposal(string memory proposalTitle, string memory proposalDescription) external {
        proposalCount++;
        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            favorVotes: 0,
            againstVotes: 0,
            canceled: false,
            announced: false,
            voterCount: 0,
            description: proposalDescription,
            title: proposalTitle,
            dateOfCreation: block.timestamp,
            deadLine: block.timestamp + 3 minutes,
            res: ProposalState.ACTIVE
        });

        proposals[newProposal.id] = newProposal;
        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            proposalDescription,
            proposalTitle,
            newProposal.dateOfCreation
        );
    }

    function getReceipt(uint256 proposalId, address voter) external view returns (VoteReceipt memory) {
        return receipts[proposalId][voter];
    }

    function stateOfTheProposal(uint256 proposalId) public returns (ProposalState) {
        uint256 totalAmountOfPassVoters;
        uint256 totalAmountOfRejectVoters;
        require(
            proposalCount >= proposalId && proposalId > 0,
            "stateOfTheProposal: invalid proposal id"
        );
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.CANCELED;
        } else if (proposal.announced) {
            if (totalAmountOfPassVoters > totalAmountOfRejectVoters) {
                proposal.res = ProposalState.ACCEPTED;
                return ProposalState.ACCEPTED;
            } else {
                proposal.res = ProposalState.REJECTED;
                return ProposalState.REJECTED;
            }
        } else {
            return ProposalState.ACTIVE;
        }
    }

    function voteToProposal(uint256 proposalId, bool vote) external {
        require(
            proposalCount >= proposalId && proposalId > 0,
            "voteToProposal: invalid proposal id"
        );
        Proposal storage proposal = proposals[proposalId];
        require(
            block.timestamp <= proposal.deadLine,
            "voteToProposal: Voting period has ended"
        );
        VoteReceipt storage receipt = receipts[proposalId][msg.sender];
        require((receipt.isVoted == false), "voteToProposal: You can't vote again");

        receipt.isVoted = true;
        receipt.isSupport = vote;
        receipt.votes = 1;
        voters[proposalId][proposal.voterCount] = msg.sender;
        proposal.voterCount++;
        if (vote) {
            proposal.favorVotes = proposal.favorVotes.add(1);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(1);
        }
        receipts[proposalId][msg.sender] = receipt;
        emit VoteCast(msg.sender, proposalId, vote);
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}