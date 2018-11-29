/*
https://github.com/shawenbin/solidity/blob/master/Dapp1.sol
uint of amount is Gwei
emit 一个 event 记录游戏过程 
*/
pragma solidity ^0.5.0;
contract Dapp1 {
    enum teamRule { dictatorship, democratic, originator }  // maximum amount, subtotal everyone, who creat team
    enum Country_Region { China, Japan, UN }
    gameConfig public config;
    team[] public Teams;
    mapping(address => uint56) public withdrawable; // Available eth can draw in Wei
    struct gameConfig {
        address developer;
        uint8 currertRound;     // max 256, the starting point is 1
        uint16 currertGame;     // max 16777216
        uint56[2] teamCharge;   // cost of building a team in Gwei, fibonacci number, [last, current]
        uint dateNode;          // defint endTime
    }
    struct team {
        string name;
        Country_Region comeFrom;
        teamRule rule;
        uint8[2] lifeCycle; // [first, last] round
        uint8 attackIndex;  // team's index in arrary
        uint56 amount;      // max 72,057,594 eth
        member[] Members;
    }
    struct member {
        address addr;
        string message;
        uint8 attackIndex;  // max 256
        uint56 amount;
    }
    constructor() public {
        config = gameConfig({developer:msg.sender, currertGame:0, currertRound:1, teamCharge:[uint56(1),2], dateNode:now});
        newGame();
    }
    function newGame() private {
        config.teamCharge = [1,2];
        config.currertGame ++;
        config.currertRound = 1;
        Teams.length = 0;
        setupTeam("United Nations Peacekeeping Forces", Country_Region.UN, teamRule.democratic, 1, 0);
    }
    function newTeam(string memory name, Country_Region comeFrom, teamRule rule, uint8 attackIndex, string memory message) public payable {
        stateCheck();
        uint56 amount = uint56(msg.value / 1000000000 - config.teamCharge[1]);
        require(amount > 0, "The amount is not enough to build up a team.");
        require(attackIndex <= Teams.length, "The direction of attack is incorrect.");
        withdrawable[config.developer] += config.teamCharge[1]; // team building cost transfer to developer account
        setupTeam(name, comeFrom, rule, attackIndex, amount);
        Teams[Teams.length-1].Members.push(member({addr:msg.sender, message:message, amount:amount, attackIndex:attackIndex}));
        }
    function setupTeam(string memory name, Country_Region comeFrom, teamRule rule, uint8 attackIndex, uint56 amount) private {
        stateCheck();
        Teams.length++;
        (Teams[Teams.length-1].name, Teams[Teams.length-1].comeFrom, Teams[Teams.length-1].rule,           Teams[Teams.length-1].lifeCycle, Teams[Teams.length-1].attackIndex, Teams[Teams.length-1].amount)
        =(                     name,                       comeFrom,                       rule, [config.currertRound,config.currertRound],                       attackIndex,                       amount);
        config.teamCharge = [config.teamCharge[1], config.teamCharge[0] + config.teamCharge[1]];    // calculate next fibonacci number
    }
    function joinTeam(uint8 teamIndex, uint8 attackIndex, string memory message) public payable {
        stateCheck();
        uint56 amount = uint56(msg.value / 1000000000);
        require(amount > 0, "The amount must be greater than 1 Gwei.");
        require(attackIndex <= Teams.length, "The direction of attack is incorrect.");
        require(Teams.length < 65538, "The team members are full, the original members are allowed to increase the amount only.");
        uint16 i = 0;
        for(; i < Teams[teamIndex].Members.length; i++) {
            if(Teams[teamIndex].Members[i].addr == msg.sender) {    // has joined before
                (Teams[teamIndex].Members[i].message, Teams[teamIndex].Members[i].attackIndex, Teams[teamIndex].Members[i].amount) = (message, attackIndex, Teams[teamIndex].Members[i].amount+amount);
                break;
            }
        }
        if(i == Teams[teamIndex].Members.length)                    // first time to join
            Teams[teamIndex].Members.push(member({addr:msg.sender, message:message, amount:amount, attackIndex:attackIndex}));
        Teams[teamIndex].amount += amount;
        sumAttack(teamIndex);
    }
    function attackTeam(uint8 attackIndex) public payable {
        stateCheck();
        require(attackIndex <= Teams.length, "The direction of attack is incorrect.");
        // check every team
    }
    function sumAttack(uint8 index) private {
        uint56 maxAmount = 0;
        uint16 i;
        uint8 attackIndex;
        if(Teams[index].rule == teamRule.dictatorship) {    // maximum amount is leader
            for(i = 0; i < Teams[index].Members.length; i++) {
                if(Teams[index].Members[i].amount >= maxAmount)
                    (maxAmount, attackIndex) = (Teams[index].Members[i].amount, Teams[index].Members[i].attackIndex);
            }
            Teams[index].attackIndex = attackIndex;
        }
        else if(Teams[index].rule == teamRule.democratic) { // subtotal everyone
            uint56[] memory totalAttacks = new uint56[](Teams.length+1);
            for(i = 0; i < Teams[index].Members.length; i++) {
                totalAttacks[Teams[index].Members[i].attackIndex] += Teams[index].Members[i].amount;
                if(totalAttacks[Teams[index].Members[i].attackIndex] >= maxAmount)
                    (attackIndex, maxAmount) = (Teams[index].Members[i].attackIndex, totalAttacks[Teams[index].Members[i].attackIndex]);
            }
            Teams[index].attackIndex = attackIndex;
        }
    }
    function stateCheck() public {
        if(now >= config.dateNode + 1 days) {
            uint8 i;
            uint8 eliminateIndex;   // eliminate Team's index number in teams arrary
            uint56 maxInjury;       // max injury
            uint56 denominator;     // total Gwei in this round
            uint56[] memory injury = new uint56[](Teams.length);
            for(i = 0; i < Teams.length; i++) {
                if(Teams[i].lifeCycle[1] == config.currertRound) {
                    denominator += Teams[i].amount;
                    if(Teams[Teams[i].attackIndex].lifeCycle[1] == config.currertRound) {
                        injury[Teams[i].attackIndex] += Teams[i].amount;
                        if(injury[Teams[i].attackIndex] > maxInjury)
                            (eliminateIndex, maxInjury) = (Teams[i].attackIndex, injury[Teams[i].attackIndex]);
                    }
                }
            }
            denominator -= Teams[eliminateIndex].amount;
            uint56 numerator = Teams[eliminateIndex].amount * 32 / 33;  // 3 percents developer fee
            withdrawable[config.developer] += Teams[eliminateIndex].amount - numerator;
            for(i = 0; i < Teams.length; i++) {     // promote
                if(Teams[i].lifeCycle[1] == config.currertRound && i != eliminateIndex) {
                    Teams[i].lifeCycle[1]++;
                    for(uint16 j = 0; j < Teams[i].Members.length; j++)
                        withdrawable[Teams[i].Members[j].addr] += Teams[i].Members[j].amount * numerator / denominator;
                }
            }
            config.dateNode += 1 days;
        }
        if(Teams.length > 2)    // goto next round
            config.currertRound++;
        else {                  // goto next game
            newGame();
        }
    }
    function drawGwei(address payable target, uint56 amount) public payable {
        uint56 fee = 1; // adjuest fee into Gwei
        require(withdrawable[msg.sender] >= amount + fee, "Balance is not enough.");
        withdrawable[msg.sender] -= amount + fee;
        target.transfer(amount * 1000000000);
    }
}
