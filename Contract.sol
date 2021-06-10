// contract template is from https://github.com/openberry-ac/crowdfunding/blob/master/contracts/Crowdfunding.sol

pragma solidity ^0.4.17;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(
        string title,
        uint durationInDays,
        uint amountToRaise,
        uint minimum,
        uint DACreturn
        ) public payable {
        uint dayAdd = durationInDays * (1 days);
        uint raiseUntil = now + (dayAdd);
        Campaign _instance = new Campaign(title,raiseUntil,amountToRaise,minimum,DACreturn, msg.sender);
        address instanceAddress = address(_instance);
        address(instanceAddress).transfer(msg.value);
        deployedCampaigns.push(instanceAddress);
    }

    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}

contract Campaign {

    enum State {
        Fundraising,
        Expired,
        Successful
    }

    string title;
    address public manager;
    uint public minimumContribution;
    uint public raiseBy;
    uint public projectGoal;
    uint DACrefund;
    uint DACfundPood;
    uint approversCount;
    mapping(address=>bool) approvers;

    State public state = State.Fundraising; 
    mapping (address => uint) public contributions;
    uint public completeAt;
    uint currentBalance;

    function () public payable {
    
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    // Modifier to check current state
    modifier inState(State _state) {
        require(state == _state);
        _;
    }


    constructor(
        string campaignTitle, 
        uint fundRaisingDeadline,
        uint goalAmount, 
        uint minimum,
        uint DACreturn,
        address creator) 
        public payable {
            require(goalAmount*(DACreturn/100) <= msg.value);
            title = campaignTitle;
            raiseBy = fundRaisingDeadline;
            projectGoal = goalAmount;
            minimumContribution = minimum;
            manager = creator;
            currentBalance = 0;
            DACrefund=DACreturn;
            DACfundPood=msg.value;
    }

    function contribute() public payable inState(State.Fundraising){
        require(msg.value > minimumContribution);
        contributions[msg.sender] = contributions[msg.sender] + (msg.value);
        currentBalance = currentBalance + (msg.value);
        approvers[msg.sender] = true;
        approversCount++;
        checkIfFundingCompleteOrExpired();
    }

    function checkIfFundingCompleteOrExpired() public {
        if (currentBalance >= projectGoal) {
            state = State.Successful;
            payOut();
        } else if (now > raiseBy)  {
            state = State.Expired;
        }
        completeAt = now;
    }

    function payOut() internal inState(State.Successful) returns (bool) {
        uint256 totalRaised = address(this).balance;
        currentBalance = 0;

        if (manager.send(totalRaised)) {
            return true;
        } else {
            currentBalance = totalRaised;
            state = State.Successful;
        }

        return false;
    }

    function getRefund() public inState(State.Expired) returns (bool) {
        require(contributions[msg.sender] > 0);

        // amount to refund is original contribution + contribution*DACrefund factor
        uint originalContribution = contributions[msg.sender];
        uint amountToRefund = originalContribution + originalContribution*(DACrefund/100);
        
        contributions[msg.sender] = 0;

        if (!msg.sender.send(amountToRefund)) {
            contributions[msg.sender] = originalContribution;
            return false;
        } 
        else {
            currentBalance = currentBalance - (originalContribution);
        }

        return true;
    }




    // need to add minimum contribution 
    // need to add distinction for DAC refund pool and contributions
    // also want to add something to update the state every time this is called
    // add if account has donated so that webpage will be able to tell them if they are due a refund

    function getDetails() public view returns 
    (
        address, string memory, uint256,
        State, uint256, uint256,uint256
    ) {
        return (
        manager,
        title,
        raiseBy,
        state,
        address(this).balance,
        projectGoal,
        DACrefund);
    }
}
