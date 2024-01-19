// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.2 <0.9.0;

contract Auction{
    address payable public auctioneer;
    uint public startblock;
    uint public endblock;

    enum auc_state {Started,Running,Ended,Cancelled}

    auc_state public auctionstate;

    uint public highest_bid;
    uint public highest_payable_bid;
    uint public bid_incr;

    address payable public highest_bidder;

    mapping(address => uint) public bids;

    constructor(){
        auctioneer = payable(msg.sender);
        auctionstate = auc_state.Running;
        startblock = block.number;
        endblock = startblock + 240;
        bid_incr = 1 ether;
    }

    modifier notowner(){
        require(msg.sender != auctioneer, "Owner Cannot Bid");
        _;
    }

    modifier Owner(){
        require(msg.sender == auctioneer, "Owner");
        _;
    }

    modifier started(){
        require(block.number > startblock);
        _;
    }

    modifier before_ended(){
        require(block.number < endblock);
        _;
    }

    modifier endauc(){
        auctionstate = auc_state.Ended;
        _;
    }

    function cancelAuc() public Owner{
        auctionstate = auc_state.Cancelled;
    }

    function min(uint a,uint b) pure private returns (uint){
        if(a <= b){
            return a;
        }
        else{
            return b;
        }
    }

    function bid() payable public notowner started before_ended{
        require(auctionstate == auc_state.Running);
        require(msg.value >= 1 ether,"min 1 ether");
        require(msg.sender != auctioneer,"owner cannot bid");

        uint currentbid = bids[msg.sender] + msg.value;

        require(currentbid > highest_payable_bid);

        bids[msg.sender] = currentbid;

        if(currentbid < bids[highest_bidder]){
            highest_payable_bid = min(currentbid + bid_incr,bids[highest_bidder]);
        }
        else{
            highest_payable_bid = min(currentbid,bids[highest_bidder] + bid_incr);
            highest_bidder = payable(msg.sender);
        }


    }

    function finaliseAuc() public{
        require(auctionstate == auc_state.Cancelled || block.number > endblock || auctionstate == auc_state.Ended);
        require(msg.sender == auctioneer || bids[msg.sender] > 0);

        address payable person;
        uint give;
        
        if(auctionstate == auc_state.Cancelled){
            person = payable(msg.sender);
            give = bids[msg.sender];
        }
        else{
            if(msg.sender == auctioneer){
                person = auctioneer;
                give = highest_payable_bid;
            }
            else{
                if(msg.sender == highest_bidder){
                    person = highest_bidder;
                    give = bids[highest_bidder] - highest_payable_bid;
                }
                else{
                    person = payable(msg.sender);
                    give = bids[msg.sender];
                }
            }
        }
        bids[msg.sender] = 0;
        person.transfer(give);
    }
}