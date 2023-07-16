//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0 <0.9.0;

contract CrwodFunding{
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minimumContribution;
    uint public target;
    uint public deadline;
    uint public raisedAmount;
    uint public noOfContributors;

    struct Request{
        address payable recipient;
        string description;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }
    mapping(uint=>Request) public requests;
    uint public numRequests;
        constructor(uint _target, uint _deadline){
        target=_target;
        deadline=block.timestamp+_deadline;// deadline is the time for which we want the contract to run after deploying
        minimumContribution=100 wei;
        manager=msg.sender;//after deploying the manager receives the message
    }

    function sendEth() public payable{
        require(block.timestamp < deadline , "Deadline has passed");
        require(msg.value >= minimumContribution,"Minimum contribution is not met");
        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    function refund() public{
        require(block.timestamp>deadline && raisedAmount<target);
        require(contributors[msg.sender]>0);
        address payable user= payable(msg.sender);
        user.transfer(contributors[msg.sender]);//it is equivalent to paying user ie msg.sender 100 wei like user.transfer(100wei) ; contributors[msg.sender] consists of some ether
        contributors[msg.sender]=0;
    }
    modifier onlyManager(){
        require(msg.sender==manager,"Only manager can call this function");
        _;
    }
    function createRequests(string memory _description,address payable _recipient,uint _value) public onlyManager{
        Request storage newRequest=requests[numRequests];//ex-requests[0] is getting pointed by newRequest
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.noOfVoters=0;
    }
    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"You must be a contributor!");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have aleady voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>=target);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"This request has already been completed");
        require(thisRequest.noOfVoters > noOfContributors/2,"Majority does not agree!");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;

    }
}
