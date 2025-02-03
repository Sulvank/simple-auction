// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract AuctionHouse {
    struct Auction {
        address seller;
        string itemName;
        string itemDescription;
        uint initialPrice;
        uint highestBid;
        address highestBidder;
        uint auctionEndTime;
        bool ended;
        mapping(address => uint) pendingReturns;
    }

    mapping(uint => Auction) public auctions;
    uint public auctionCount;

    event AuctionCreated(uint auctionId, address seller, string itemName, uint initialPrice, uint duration);
    event AuctionEnded(uint auctionId, address winner, uint amount);
    event NewBid(uint auctionId, address bidder, uint amount);
    event BidWithdrawn(uint auctionId, address bidder, uint amount);

    function createAuction(string memory _itemName, string memory _itemDescription, uint _initialPrice, uint _duration) external {
        require(_initialPrice > 0, "Initial price must be greater than zero.");
        require(_duration > 0, "Auction duration must be greater than zero.");

        auctionCount++;
        Auction storage newAuction = auctions[auctionCount];

        newAuction.seller = msg.sender;
        newAuction.itemName = _itemName;
        newAuction.itemDescription = _itemDescription;
        newAuction.initialPrice = _initialPrice;
        newAuction.highestBid = _initialPrice;
        newAuction.auctionEndTime = block.timestamp + _duration;
        newAuction.ended = false;

        emit AuctionCreated(auctionCount, msg.sender, _itemName, _initialPrice, _duration);
    }

    function bid(uint _auctionId) external payable {
        Auction storage auction = auctions[_auctionId];

        require(block.timestamp < auction.auctionEndTime, "Auction already ended.");
        require(msg.value > auction.highestBid, "There already is a higher bid.");

        if (auction.highestBid != 0) {
            auction.pendingReturns[auction.highestBidder] += auction.highestBid;
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit NewBid(_auctionId, msg.sender, msg.value);
    }

    function withdraw(uint _auctionId) external {
        Auction storage auction = auctions[_auctionId];
        uint amount = auction.pendingReturns[msg.sender];

        require(amount > 0, "Nothing to withdraw.");
        auction.pendingReturns[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit BidWithdrawn(_auctionId, msg.sender, amount);
    }

    function endAuction(uint _auctionId) external {
        Auction storage auction = auctions[_auctionId];

        require(msg.sender == auction.seller, "Only seller can end the auction.");
        require(block.timestamp >= auction.auctionEndTime, "Auction not yet ended.");
        require(!auction.ended, "Auction has already ended.");

        auction.ended = true;
        payable(auction.seller).transfer(auction.highestBid);

        emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid);
    }
}
