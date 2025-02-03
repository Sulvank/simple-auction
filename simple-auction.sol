// Licencia
// SPDX-License-Identifier: LGPL-3.0-only


// Version
pragma solidity 0.8.28;

// Contract
contract SimpleAuction {

    uint256 public auctionEndTime;
    uint256 public initialPrice;
    uint256 public highestBid;
    address public highestBidder;
    address public owner;
    bool public ended;
    mapping(address => uint) public pendingReturns;

    event AuctionEnded(address winner, uint amount);
    event NewBid(address bidder, uint amount);
    event BidWithdrawn(address bidder, uint amount);

    constructor(uint _biddingTime, uint256 _initialPrice) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime;
        initialPrice = _initialPrice;
    }

    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction already ended.");
        require(msg.value > highestBid, "There already is a higher bid.");

        if(highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit NewBid(msg.sender, msg.value);
    }

    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "Nothing to withdraw.");

        pendingReturns[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit BidWithdrawn(msg.sender, amount);
        return true;
    }

    function endAuction() external {
        require(msg.sender == owner, "Only owner can end the auction.");
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "Auction has already ended.");
        
        ended = true;
        payable(owner).transfer(highestBid);
        emit AuctionEnded(highestBidder, highestBid);
    }
}