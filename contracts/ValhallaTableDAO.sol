// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

//Interface for the NFTMarketplace
interface INFTMarketplace {
    //returns the price of an NFT from the NFTMarketplace
    function getPrice() external view returns (uint256);

    //returns whether or not the given _tokenId has already been purchased
    function available(uint256 _tokenId) external view returns (bool);

    //purchases an NFT from the NFTMarketplace
    function purchase(uint256 _tokenId) external payable;
}

//Interface for ValhallaNFT
interface IValhallaNFT {
    //the number of NFTs owned by the given address
    function balanceOf(address owner) external view returns (uint256);

    //returns a tokenID at given index for owner
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);
}

contract ValhallaTableDAO is Ownable {
    // Create a struct named Proposal containing all relevant information
    struct Proposal {
        uint256 nftTokenId;
        uint256 deadline;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        // voters - a mapping of CryptoDevsNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not
        mapping(uint256 => bool) voters;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals;

    enum Vote {
        YAY, // YAY = 0
        NAY // NAY = 1
    }

    INFTMarketplace nftMarketplace;
    IValhallaNFT valhallaNFT;

    constructor(address _nftMarketplace, address _valhallaNFT) payable {
        nftMarketplace = INFTMarketplace(_nftMarketplace);
        valhallaNFT = IValhallaNFT(_valhallaNFT);
    }

    modifier nftHolderOnly() {
        require(valhallaNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    //Returns the proposal index for the newly created proposal
    function createProposal(
        uint256 _nftTokenId
    ) external nftHolderOnly returns (uint256) {
        require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        // Set the proposal's voting deadline to be (current time + 5 minutes)
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;

        return numProposals - 1;
    }

    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    function voteOnProposal(
        uint256 proposalIndex,
        Vote vote
    ) external nftHolderOnly activeProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voterNFTBalance = valhallaNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        // Calculate how many NFTs are owned by the voter
        // that haven't already been used for voting on this proposal
        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = valhallaNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    function executeProposal(
        uint256 proposalIndex
    ) external nftHolderOnly inactiveProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];

        // If the proposal has more YAY votes than NAY votes
        // purchase the NFT from the FakeNFTMarketplace
        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    /// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
    function withdrawEther() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw, contract balance empty");
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "FAILED_TO_WITHDRAW_ETHER");
    }

    receive() external payable {}

    fallback() external payable {}
}
