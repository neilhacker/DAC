# DAC

Dominant Assurance contracts are a way of incentivising donations to crowdfunded goods by making donating a strictly dominant action for someone who likes the project. This is a smart contract implementation of this idea.

There are two contracts:

CampaignFactory - This is the factory contract which creates and stores instances of the campaigns. 

Campaign - This is the actual DAC. At the moment when creating the contract the creator must also specify what percentage of peoples donations they will get back in addition to their actual donation if the campaign fails (the DACrefund) and must send enough in the transaction to cover this based on the goal amount. Currently only percantage rewards are considered as any constant reward is liable to a sybil attack. 
