// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTLottery is ERC721URIStorage, VRFConsumerBase, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    /// @notice Emitted after a bid is placed
    /// @param bidder Address of user who placed bid
    /// @param auctionId ID of the auction
    /// @param value Ether value placed on bid
    /// @param bidders Total bidder count
    event Bid(address indexed bidder, uint indexed auctionId, uint value, uint bidders);

    /// @notice Emitted after a bid amount is withdrawed
    /// @param bidder Address of the user withdrawing bid
    /// @param auctionId ID of the auction
    /// @param value Ether value withdrawed from bid
    event Withdraw(address indexed bidder, uint indexed auctionId, uint value);

    /// @notice Emitted after a winner is chosen
    /// @param winner Address of the user being rewarded
    /// @param auctionId ID of the auction
    /// @param tokenId Token ID of the newly minted nft
    event Reward(address indexed winner, uint auctionId, uint tokenId);

    /// @notice Emitted after a new auction is started
    /// @param auctionId ID of the auction
    /// @param bidAmount Ether value for each bid
    event NewAuction(uint auctionId, uint indexed bidAmount);

    uint public auctionCount;

    bytes32 internal keyHash;
    uint256 internal fee;

    struct Auction {
        bool status;
        uint bidAmount;
        uint currentBidders;
        mapping(uint => address) bidders;
        mapping(address => uint) userBids;
    }

    mapping(uint => Auction) private auctions;
    // mapping(bytes32 => string) private uris;

    constructor() public ERC721("Lottery", "LOT") VRFConsumerBase(0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, 0x01BE23585060835E02B77ef475b0Cc51aA1e0709) {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }

    /// @notice Requests randomness 
    function getRandomNumber() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /// @notice Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint winnerNumber = (randomness % auctions[auctionCount].currentBidders) + 1;
        awardNFT(auctions[auctionCount].bidders[winnerNumber]);
    }

    /// @notice Generates "random" number from block timestamp for testing purposes on local chains
    function fakeRandomNumber() private {
        uint random = (block.timestamp % auctions[auctionCount].currentBidders) + 1;
        awardNFT(auctions[auctionCount].bidders[random]);
    }

    /// @notice Awards new token/nft for user
    /// @param user User's address for NFT to be minted to
    function awardNFT(address user) private {
        _tokenIds.increment();

        auctions[auctionCount].status = false;

        uint256 newTokenId = _tokenIds.current();
        _mint(user, newTokenId);
        _setTokenURI(newTokenId, _tokenURIs[newTokenId]);

        emit Reward(user, auctionCount, newTokenId);
    }

    /// @notice Called by user to bid on current auction (only if auction is active, and msg.value is equal to set bid amount)
    function bid() public payable {
        require(auctions[auctionCount].status == true, "Auction must be active");
        require(msg.value == auctions[auctionCount].bidAmount, "Incorrect value for bid amount");

        auctions[auctionCount].currentBidders++;
        auctions[auctionCount].bidders[auctions[auctionCount].currentBidders] = msg.sender;        
        auctions[auctionCount].userBids[msg.sender] = msg.value;
        
        emit Bid(msg.sender, auctionCount, msg.value, auctions[auctionCount].currentBidders);
    }

    /// @notice Called by user to withdraw funds from an inactive auction 
    /// @param auctionId Auction ID for bid funds to be withdrawed from
    function withdraw(uint auctionId) external {
        require(auctions[auctionId].userBids[msg.sender] > 0, "No bid found");
        require(auctions[auctionId].status != true, "Auction still active");

        uint bid = auctions[auctionId].userBids[msg.sender]; 
        auctions[auctionId].userBids[msg.sender] = 0;

        (bool sent, bytes memory data) = msg.sender.call{value: bid}("");
        require(sent, "Failed to send");

        emit Withdraw(msg.sender, auctionId, bid);
    }

    /// @notice Called by owner to draw winner with chainlink VRF
    function drawWinner() external onlyOwner {
        getRandomNumber();
        // fakeRandomNumber();
    }

    /// @notice Called by owner to start new auction
    /// @param bidAmount Set amount in ether value for all bids
    function startNewAuction(uint bidAmount) external onlyOwner {
        auctionCount++;
        auctions[auctionCount].bidAmount = bidAmount;
        auctions[auctionCount].status = true;

        emit NewAuction(auctionCount, bidAmount);
    }

    function setTokenURI(uint tokenId, string memory tokenURI) external onlyOwner {
        _tokenURIs[tokenId] = tokenURI;
    }

    /// @notice Returns total supply of Lottery tokens/NFTs
    function totalSupply() public view returns(uint) {
        return _tokenIds.current();
    }
}
