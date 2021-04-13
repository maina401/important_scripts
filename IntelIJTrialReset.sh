#!/bin/sh

rm  -f ~/.config/JetBrains/IntelliJIdea*/eval/idea*.evaluation.key && \
sed -i '/evlsprt/d' ~/.config/JetBrains/IntelliJIdea*/options/other.xml && \
rm -rf ~/.java/.userPrefs/jetbrains

# It is Highly Advised to Purchase the JetBrain Softwares
# This is only for the case You just want to Extend the 
# Trial Period and Evaluate the IDE for some more Time
