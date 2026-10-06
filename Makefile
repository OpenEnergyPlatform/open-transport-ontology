ONTOLOGY_NAME := oto
IRI_NAME := oto

# dont replace IRIs
IRI_PLACEHOLDER := https:\/\/w3id.org\/
IRI_BASE := https:\/\/w3id.org\/
#IRI_BASE := https:\/\/openenergyplatform.github.io\/

IRI_ONTOLOGY_PLACEHOLDER := $(IRI_PLACEHOLDER)$(ONTOLOGY_NAME)
IRI_ONTOLOGY := $(IRI_BASE)$(IRI_NAME)

MKDIR_P = mkdir -p
VERSION:= $(shell cat VERSION)
VERSIONDIR := build/$(ONTOLOGY_NAME)/$(VERSION)
ONTOLOGY_SOURCE := src/ontology
SCRIPTS := src/scripts
BFO_SOURCE := https://raw.githubusercontent.com/BFO-ontology/BFO/v2019-08-26/bfo_classes_only.owl
TMP := tmp
IMPORTS := $(ONTOLOGY_SOURCE)/imports

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	SED := sed
endif
ifeq ($(UNAME_S),Darwin)
	SED := gsed
endif


subst_paths =	${subst $(ONTOLOGY_SOURCE),$(VERSIONDIR),${patsubst $(ONTOLOGY_SOURCE)/edits/%,$(ONTOLOGY_SOURCE)/modules/%,$(1)}}
subst_paths_owl =	${subst $(VERSIONDIR),$(VERSIONDIR)/owl,${patsubst %.ttl,%.owl,$(1)}}

OWL_FILES := $(call subst_paths,$(shell find $(ONTOLOGY_SOURCE)/* -type f -name "*.owl"))
OMN_FILES := $(call subst_paths,$(shell find $(ONTOLOGY_SOURCE)/* -type f -name "*.omn"))
TTL_FILES := $(call subst_paths,$(shell find $(ONTOLOGY_SOURCE)* -type f -name "*.ttl"))

SEPARATOR := \/

OWL_COPY := $(OWL_FILES)

OMN_COPY :=	$(OMN_FILES)

TTL_COPY :=	$(TTL_FILES)

OMN_TRANSLATE := ${patsubst %.omn,%.owl,$(OMN_FILES)}
TTL_TRANSLATE := $(call subst_paths_owl,$(TTL_COPY))


RM=/bin/rm
ROBOT_PATH := robot.jar
ROBOT := java -jar $(ROBOT_PATH)

define replace_devs
	$(SED) -i -E "s/$(IRI_ONTOLOGY)\/dev\/([a-zA-Z/\.\-]+)/$(IRI_ONTOLOGY)\/releases\/$(VERSION)\/\1/m" $1
endef

define replace_oms
	$(SED) -i -E "s/($(IRI_ONTOLOGY)\/dev\/([a-zA-Z/\-]+)\.)omn/\1owl/m" $1
	$(SED) -i -E "s/($(IRI_ONTOLOGY)\/releases\/$(VERSION)\/([a-zA-Z/\-]+)\.)omn/\1owl/m" $1
endef

define replace_ttls
	$(SED) -i -E "s/($(IRI_ONTOLOGY)\/dev\/([a-zA-Z/\-]+)\.)ttl/\1owl/m" $1
	$(SED) -i -E "s/($(IRI_ONTOLOGY)\/releases\/$(VERSION)\/([a-zA-Z/\-]+)\.)ttl/\1owl/m" $1
endef

define replace_owls
	$(SED) -i -E "s/($(IRI_ONTOLOGY)\/dev\/([a-zA-Z/\-]+)\.)owl/\1ttl/m" $1
	$(SED) -i -E "s/($(IRI_ONTOLOGY)\/releases\/$(VERSION)\/([a-zA-Z/\-]+)\.)owl/\1ttl/m" $1
endef

define replace_ttls_owx
	$(SED) -i -E "s/($(IRI_ONTOLOGY)\/dev\/([a-zA-Z/\-]+)\.)ttl/\1owx/m" $1
	$(SED) -i -E "s/($(IRI_ONTOLOGY)\/releases\/$(VERSION)\/([a-zA-Z/\-]+)\.)ttl/\1owx/m" $1
endef

define replace_ttls_owx
	$(SED) -i -E "s/($(OEP_BASE)\/dev\/([a-zA-Z/\-]+)\.)ttl/\1owx/m" $1
	$(SED) -i -E "s/($(OEP_BASE)\/releases\/$(VERSION)\/([a-zA-Z/\-]+)\.)ttl/\1owx/m" $1
endef

define translate_to_owl
	$(ROBOT) convert --catalog $(VERSIONDIR)/catalog-v001.xml --input $2 --output $1 --format owl
	$(call replace_ttls,$1)
	$(call replace_devs,$1)
endef

define translate_to_ttl
	$(ROBOT) convert --catalog $(VERSIONDIR)/catalog-v001.xml --input $2 --output $1 --format ttl
	$(call replace_owls,$1)
	$(call replace_devs,$1)
endef

define translate_to_omn
	$(ROBOT) convert --catalog $(VERSIONDIR)/catalog-v001.xml --input $2 --output $1 --format omn
	$(call replace_owls,$1)
	$(call replace_devs,$1)
endef

define translate_to_owx
	$(ROBOT) convert --catalog $(VERSIONDIR)/catalog-v001.xml --input $2 --output $1 --format owx
	$(call replace_ttls_owx,$1)
	$(call replace_devs,$1)
endef

define replace_placeholder
	$(SED) -i -E "s/$(IRI_ONTOLOGY_PLACEHOLDER)\/([a-zA-Z/\.\-]+)/$(IRI_ONTOLOGY)\/\1/m" $1
	$(SED) -i -E "s/$(IRI_ONTOLOGY_PLACEHOLDER)\//$(IRI_ONTOLOGY)\//m" $1
endef

.PHONY: all clean base merge directories

all: base merge owx

imports: ${TMP} ${TMP}/catalog.xml $(IMPORTS) $(IMPORTS)/bfo_classes_only.owl $(IMPORTS)/cco-extracted.ttl

base: | directories imports $(VERSIONDIR)/catalog-v001.xml robot.jar  $(TTL_COPY) $(OWL_COPY) $(OWLVERSION) $(TTL_TRANSLATE)

merge: | $(VERSIONDIR)/$(ONTOLOGY_NAME)-full.ttl

owx: | $(VERSIONDIR)/$(ONTOLOGY_NAME)-full.owx

clean:
	- $(RM) -r $(VERSIONDIR)
	- $(RM) -r ${TMP}
clean-imports:
	- $(RM) -r $(IMPORTS)/*

directories: ${VERSIONDIR}/imports ${VERSIONDIR}/modules ${TMP} $(VERSIONDIR)/owl


$(IMPORTS):
	${MKDIR_P} ${IMPORTS}

$(IMPORTS)/bfo_classes_only.owl:
	curl -L -o $@ $(BFO_SOURCE)

$(IMPORTS)/cco-extracted.ttl: $(ROBOT_PATH)
	bash src/scripts/cco-imports/cco-extracted.sh

${TMP}:
	${MKDIR_P} ${TMP}

${TMP}/catalog.xml:
	cp assets/catalog.xml  $@

$(VERSIONDIR)/owl:
	${MKDIR_P} $(VERSIONDIR)/owl

${VERSIONDIR}/imports:
	${MKDIR_P} ${VERSIONDIR}/imports

${VERSIONDIR}/modules:
	${MKDIR_P} ${VERSIONDIR}/modules

$(VERSIONDIR)/catalog-v001.xml: $(ONTOLOGY_SOURCE)/catalog-v001.xml
	cp $< $@
	$(call replace_placeholder,$@)
	$(call replace_devs,$@)
	$(SED) -i -E "s/edits\//modules\//m" $@

$(ROBOT_PATH): | build
	curl -L -o $@ https://github.com/ontodev/robot/releases/download/v1.9.10/robot.jar

$(VERSIONDIR)/owl/%.owl: $(VERSIONDIR)/%.ttl
	$(call translate_to_owl,$@,$<)

$(VERSIONDIR)/owl/modules/%.owl: $(VERSIONDIR)/edits/%.ttl
	$(call translate_to_owl,$@,$<)

$(VERSIONDIR)/owl/%.owl: $(ONTOLOGY_SOURCE)/%.owl
	cp -a $< $@
	$(call replace_placeholder,$@)
	$(call replace_devs,$@)

$(VERSIONDIR)/owl/modules/%.owl: $(ONTOLOGY_SOURCE)/edits/%.owl
	cp -a $< $@
	$(call replace_placeholder,$@)
	$(call replace_devs,$@)

$(VERSIONDIR)/modules/%.ttl: $(ONTOLOGY_SOURCE)/edits/%.ttl
	cp -a $< $@
	$(call replace_placeholder,$@)
	$(call replace_devs,$@)

$(VERSIONDIR)/%.ttl: $(ONTOLOGY_SOURCE)/%.ttl
	cp -a $< $@
	$(call replace_placeholder,$@)
	$(call replace_devs,$@)

$(VERSIONDIR)/%.owl: $(ONTOLOGY_SOURCE)/%.owl
	cp -a $< $@
	$(call replace_placeholder,$@)
	$(call replace_devs,$@)

$(VERSIONDIR)/$(ONTOLOGY_NAME)-full.ttl : | base
	$(ROBOT) merge --catalog $(VERSIONDIR)/catalog-v001.xml $(foreach f, $(VERSIONDIR)/$(ONTOLOGY_NAME).ttl $(TTL_COPY) $(OWL_COPY), --input $(f)) annotate --ontology-iri $(IRI_ONTOLOGY)$(SEPARATOR) --version-iri $(IRI_ONTOLOGY)/releases/$(VERSION)/$(ONTOLOGY_NAME)-full.ttl --output $@
	$(call replace_owls,$@)

$(VERSIONDIR)/owl/$(ONTOLOGY_NAME)-full.owl : $(VERSIONDIR)/$(ONTOLOGY_NAME)-full.ttl
	$(call translate_to_ttl,$@,$<)
	$(call replace_ttls,$@)

$(VERSIONDIR)/$(ONTOLOGY_NAME)-full.owx : $(VERSIONDIR)/$(ONTOLOGY_NAME)-full.ttl
	$(call translate_to_owx,$@,$<)
