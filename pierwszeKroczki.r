setwd("/Users/Marcin/Documents/R/modelemieszaneiliniowe/SecondProject")

library("lme4")
library("data.table")
library("ggplot2")
library("reshape")
library("dplyr")
head(load("dendriticSpines.rda"))

head(dendriticSpines)
summary(dendriticSpines)

length(levels(as.factor(dendriticSpines[,3])))
length(levels(as.factor(dendriticSpines[,2])))
length(levels(as.factor(dendriticSpines[,1])))

tabelka <- dendriticSpines

# dlugosc spajnow dla kazdego leczenie
dlugoscSpajnowPerLeczenie <- ggplot(data = tabelka, aes(x = treatment, y = length)) +
    geom_boxplot(aes(fill = treatment))

# srednia dlugosc spajnow dla kazdego z 3 typow myszy
dlugoscSpajnowPerTypMyszy <- ggplot(data = tabelka, aes(x = mouse, y = length)) +
    geom_boxplot(aes(fill = mouse))
# ewentualnie:
# bwplot(length~mouse, data=tabelka, ylab="pitu to pitu")

# dla kazdego typu leczenia widać ew. różnice
# w długości spajnów między rodzajami myszy
dlSPajnowPerleczeniaROzrozniajacTypyMysz <- ggplot(data = tabelka, aes(x = treatment, y = length)) +
    geom_boxplot(aes(fill = mouse))

# dla każdego typu myszy widać różnice między długościami spajnów
# dla różnych leczeń
dlSpajnowPerTypMyszyROzrozniajacLeczenie <- ggplot(data = tabelka, aes(x = mouse, y = length)) +
    geom_boxplot(aes(fill = treatment))



# Warto popatrzeć:

# np. lit daje najkrótsze spajny
dlugoscSpajnowPerLeczenie

# np. KO maja wyrozniajace sie dlugosc (bardziej krótkość) spajnów
dlugoscSpajnowPerTypMyszy

# na następnych dwóch rysunkach widać, że nie każdy typ myszy był poddawany każdemu leczeniu
dlSpajnowPerTypMyszyROzrozniajacLeczenie
dlSPajnowPerleczeniaROzrozniajacTypyMysz



# w fazie pierwszej mieliśmy obczaić interakcję
# typu myszki z typem 'leczenia' jakiemu został poddany
# wycinek z jej mózgu

# Weźmy na początek mouse i treatment jako efekty stałe
# a rodzaj myszki jako efekt losowy
modelM <- lmer(length ~ mouse +
    treatment + treatment:mouse +
    (1|Animal), data=tabelka)

summary(modelM)


# czy cokolwiek z tego wynika, to ja nie wiem...
ranefM = ranef(modelM, condVar =TRUE)
dotplot(ranefM)





# Moje wypociny w formie data.table - podobno fajny pomysł bo data.table ma działać dużo szybciej niż data.frame [ZGADZAM SI�]
# DTabelka <- data.table(as.integer(dendriticSpines[,1]),dendriticSpines[,2],dendriticSpines[,3],dendriticSpines[,4],dendriticSpines[,5],dendriticSpines[,6],dendriticSpines[,7])
# sapply(DTabelka, class)
# names(DTabelka) <- names(dendriticSpines)
# dim(DTabelka)
# tables()
# setkey(DTabelka, "Animal")
# summary(DTabelka)

# DTabelka[Animal==3,]
# DTabelka[Photo_ID_abs==3,]
# DTabelka[spine_number==3,]
# tabelka[,summary(lm(length~mouse+treatment+mouse:treatment))]
# tabelka[,lmer(length~mouse+treatment+(1|spine_number))]


#####################################################################################
spines <- data.table(dendriticSpines)

##Wybieramy study
spines[, .N, by = Study]
selectedStudy <- "ko"
spines <- filter(spines, Study == selectedStudy)
list <- split(spines$mouse, spines$treatment)

#W ka�dym study analizowane s� tylko dwa rodzaje treatment oraz dwa typy myszy. 
#W "ko" jest to odpowiednio: brak treatment, li oraz KO, WT. Pozosta�e poziomy obu zmiennych usuwamy.
sapply(list, summary)
spines$mouse <- factor(spines$mouse)
spines$treatment <- factor(spines$treatment)
spines$Photo_ID_abs <- factor(spines$Photo_ID_abs)
spines$spine_number <- factor(spines$spine_number)

#przyjrzyjmy si� dok�adniej liczbie spajn�w na poszczeg�lnych zdj�ciach - czy jest zale�no�� mi�dzy g�sto�ci� sieci
#spajn�w a d�ugo�ci�? [nie jestem przekonana, czy tu co� wykryjemy...]
spines[, "Animal:Photo" := paste(Animal, Photo_ID_abs, sep = ":")]
list <- split(spines$spine_number, spines$`Animal:Photo`)
sapply(list, max)
spines[, noOfSpines := max(spine_number), by = 'Animal:Photo']

#Szukamy interakcji
aggregate(length ~ mouse + treatment, data = spines, FUN = "mean")
interaction.plot(spines$mouse, spines$treatment, spines$length)
#Mo�emy si� wi�c spodziewa�, �e WT w po��czeniu z brakiem treatment daje d�u�sze spajny.

#Budujemy model.
model <- lmer(length ~ treatment*mouse + (1|Animal:Photo_ID_abs), data = spines)
summary(model) #trzeba przekszta�ci� warto�ci t na p-value

#Budujemy model, dodaj�c liczb� spajn�w
model2 <- lmer(length ~ treatment*mouse + (1|Animal), data = spines)
summary(model2)


#Kt�ry model lepszy?
anova(model, model2) #mo�emy zosta� przy pierwszym

model3 <- lmer(length ~ treatment*mouse + (1|Animal:Photo_ID_abs), data = spines)
summary(model3)

anova(model2, model3)


#DO ZROBIENIA:

#Diagnostyka
      ##Czy epsilon ma rozk�ad normalny?
      ##Czy u ma rozk�ad normalny?
      ##Czy wszystkie zmienne s� istotne? - testy permutacyjne
      ##Obrazki

      