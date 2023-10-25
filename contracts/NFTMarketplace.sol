// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract NFTMarketplace {
    mapping(uint256 => address) public tokens;

    uint256 nftPrice = 0.1 ether;
    
    //Purchase nft from marketplace with tokenID
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT costs 0.1 ether");
        tokens[_tokenId] = msg.sender;
    }

    //returns the price of one NFT
    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    //checks whether the given tokenId has already been sold or not
    function available(uint256 _tokenId) external view returns (bool) {
        if (tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }
}
