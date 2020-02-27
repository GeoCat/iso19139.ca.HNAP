<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:gmd="http://www.isotc211.org/2005/gmd" xmlns:gts="http://www.isotc211.org/2005/gts"
                xmlns:gco="http://www.isotc211.org/2005/gco" xmlns:gmx="http://www.isotc211.org/2005/gmx"
                xmlns:srv="http://www.isotc211.org/2005/srv" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:gml="http://www.opengis.net/gml/3.2"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:gn="http://www.fao.org/geonetwork"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:gn-fn-core="http://geonetwork-opensource.org/xsl/functions/core"
                xmlns:gn-fn-metadata="http://geonetwork-opensource.org/xsl/functions/metadata"
                xmlns:gn-fn-iso19139="http://geonetwork-opensource.org/xsl/functions/profiles/iso19139"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:ns2="http://www.w3.org/2004/02/skos/core#"
                xmlns:xslutil="java:org.fao.geonet.util.XslUtil"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:exslt="http://exslt.org/common" exclude-result-prefixes="#all">

  <xsl:variable name="thesauriDir" select="/root/gui/thesaurusDir" />
  <xsl:variable name="resourceFormatsTh" select="document(concat('file:///', replace(concat($thesauriDir, '/local/thesauri/theme/EC_Resource_Formats.rdf'), '\\', '/')))" />


  <!-- Hide thesaurus name in default view -->
  <xsl:template mode="mode-iso19139" priority="2005" match="gmd:thesaurusName[$tab='default']" />

  <!-- Hide protocol for contacts in default view -->
  <xsl:template mode="mode-iso19139" priority="2005" match="gmd:protocol[$tab='default']" />


  <!-- ===================================================================== -->
  <!-- gml:TimePeriod (format = %Y-%m-%dThh:mm:ss) -->
  <!-- ===================================================================== -->
  <xsl:template mode="mode-iso19139" match="gml:beginPosition[$schema='iso19139.nap']|gml:endPosition[$schema='iso19139.nap']|gml:timePosition[$schema='iso19139.nap']"
                priority="2000">

    <xsl:variable name="xpath" select="gn-fn-metadata:getXPath(.)"/>
    <xsl:variable name="value" select="normalize-space(text())"/>


    <xsl:variable name="attributes">
      <xsl:if test="$isEditing">
        <!-- Create form for all existing attribute (not in gn namespace)
        and all non existing attributes not already present. -->
        <xsl:apply-templates mode="render-for-field-for-attribute"
                             select="             @*|           gn:attribute[not(@name = parent::node()/@*/name())]">
          <xsl:with-param name="ref" select="gn:element/@ref"/>
          <xsl:with-param name="insertRef" select="gn:element/@ref"/>
        </xsl:apply-templates>
      </xsl:if>
    </xsl:variable>


    <xsl:call-template name="render-element">
      <xsl:with-param name="label"
                      select="gn-fn-metadata:getLabel($schema, name(), $labels, name(..), '', $xpath)/label"/>
      <xsl:with-param name="name" select="gn:element/@ref"/>
      <xsl:with-param name="value" select="text()"/>
      <xsl:with-param name="cls" select="local-name()"/>
      <xsl:with-param name="xpath" select="$xpath"/>
      <!--
          Default field type is Date.
          TODO : Add the capability to edit those elements as:
           * xs:time
           * xs:dateTime
           * xs:anyURI
           * xs:decimal
           * gml:CalDate
          See http://trac.osgeo.org/geonetwork/ticket/661
        -->
      <xsl:with-param name="type"
                      select="if (string-length($value) = 10 or $value = '') then 'date' else 'datetime'"/>
      <xsl:with-param name="editInfo" select="gn:element"/>
      <xsl:with-param name="attributesSnippet" select="$attributes"/>
    </xsl:call-template>
  </xsl:template>

            <!-- Readonly elements -->
  <xsl:template mode="mode-iso19139" priority="2005" match="gmd:fileIdentifier|gmd:dateStamp">
      <xsl:variable name="xpath" select="gn-fn-metadata:getXPath(.)" />

      <xsl:call-template name="render-element">
      <xsl:with-param name="label"
                      select="gn-fn-metadata:getLabel($schema, name(), $labels)"/>
      <xsl:with-param name="value" select="*"/>
      <xsl:with-param name="cls" select="local-name()"/>
      <xsl:with-param name="xpath" select="$xpath"/>
      <xsl:with-param name="type" select="gn-fn-metadata:getFieldType($editorConfig, name(), '', $xpath)"/>
      <xsl:with-param name="name" select="''"/>
      <xsl:with-param name="editInfo" select="*/gn:element"/>
      <xsl:with-param name="parentEditInfo" select="gn:element"/>
      <xsl:with-param name="isDisabled" select="true()"/>
    </xsl:call-template>
  </xsl:template>


  <xsl:template mode="mode-iso19139" match="gmd:organisationName" priority="2000">

    <xsl:variable name="xpath" select="gn-fn-metadata:getXPath(.)"/>
    <xsl:variable name="isoType" select="if (../@gco:isoType) then ../@gco:isoType else ''"/>
    <xsl:variable name="labelConfig" select="gn-fn-metadata:getLabel($schema, name(), $labels, name(..), $isoType, $xpath)"/>

   <xsl:variable name="theElement" select="." />

    <xsl:variable name="values">
      <values>
        <!-- Or the PT_FreeText element matching the main language -->
        <xsl:if test="gco:CharacterString">
          <!--<xsl:message>V: <xsl:value-of select="gco:CharacterString" /></xsl:message>-->
          <value ref="{gco:CharacterString/gn:element/@ref}" lang="{$metadataLanguage}">
            <xsl:value-of select="gco:CharacterString"/>
          </value>
          <!--<xsl:message>value main: <xsl:value-of select="gco:CharacterString" /> - <xsl:value-of select="gco:CharacterString/gn:element/@ref" /></xsl:message>-->
        </xsl:if>

        <!-- the existing translation -->
        <xsl:for-each select="gmd:PT_FreeText/gmd:textGroup/gmd:LocalisedCharacterString">
          <value ref="{gn:element/@ref}" lang="{substring-after(@locale, '#')}">
            <xsl:value-of select="."/>
          </value>
          <!--<xsl:message>value alt 1:  <xsl:value-of select="." /> - <xsl:value-of select="gn:element/@ref" /> <xsl:value-of select="substring-after(@locale, '#')" /></xsl:message>-->
        </xsl:for-each>

        <!-- and create field for none translated language -->
        <xsl:for-each select="$metadataOtherLanguages/lang">
          <xsl:variable name="currentLanguageId" select="@id"/>
          <xsl:if test="count($theElement/
                gmd:PT_FreeText/gmd:textGroup/
                gmd:LocalisedCharacterString[@locale = concat('#',$currentLanguageId)]) = 0">
            <value ref="lang_{@id}_{$theElement/parent::node()/gn:element/@ref}"
                   lang="{@id}"></value>

            <!--<xsl:message>value alt 1: <xsl:value-of select="$theElement/parent::node()/gn:element/@ref" /> <xsl:value-of select="@id" /></xsl:message>-->

          </xsl:if>
        </xsl:for-each>
      </values>
    </xsl:variable>

    <xsl:call-template name="render-element">
      <xsl:with-param name="label"
                      select="$labelConfig"/>
      <xsl:with-param name="value" select="$values"/>
      <xsl:with-param name="cls" select="local-name()"/>
      <xsl:with-param name="xpath" select="$xpath"/>
      <xsl:with-param name="directive" select="'gn-organisation-entry-selector-ec'"/>
      <xsl:with-param name="editInfo" select="gn:element"/>
      <xsl:with-param name="parentEditInfo" select="../gn:element"/>
    </xsl:call-template>

  </xsl:template>


  <xsl:template mode="mode-iso19139" match="gmd:country" priority="2000">

    <xsl:variable name="xpath" select="gn-fn-metadata:getXPath(.)"/>
    <xsl:variable name="isoType" select="if (../@gco:isoType) then ../@gco:isoType else ''"/>
    <xsl:variable name="labelConfig" select="gn-fn-metadata:getLabel($schema, name(), $labels, name(..), $isoType, $xpath)"/>

    <xsl:variable name="theElement" select="." />

    <xsl:variable name="values">
      <values>
        <!-- Or the PT_FreeText element matching the main language -->
        <xsl:if test="gco:CharacterString">
          <!--<xsl:message>V: <xsl:value-of select="gco:CharacterString" /></xsl:message>-->
          <value ref="{gco:CharacterString/gn:element/@ref}" lang="{$metadataLanguage}">
            <xsl:value-of select="gco:CharacterString"/>
          </value>
          <!--<xsl:message>value main: <xsl:value-of select="gco:CharacterString" /> - <xsl:value-of select="gco:CharacterString/gn:element/@ref" /></xsl:message>-->
        </xsl:if>

        <!-- the existing translation -->
        <xsl:for-each select="gmd:PT_FreeText/gmd:textGroup/gmd:LocalisedCharacterString">
          <value ref="{gn:element/@ref}" lang="{substring-after(@locale, '#')}">
            <xsl:value-of select="."/>
          </value>
          <!--<xsl:message>value alt 1:  <xsl:value-of select="." /> - <xsl:value-of select="gn:element/@ref" /> <xsl:value-of select="substring-after(@locale, '#')" /></xsl:message>-->
        </xsl:for-each>

        <!-- and create field for none translated language -->
        <xsl:for-each select="$metadataOtherLanguages/lang">
          <xsl:variable name="currentLanguageId" select="@id"/>
          <xsl:if test="count($theElement/
                gmd:PT_FreeText/gmd:textGroup/
                gmd:LocalisedCharacterString[@locale = concat('#',$currentLanguageId)]) = 0">
            <value ref="lang_{@id}_{$theElement/parent::node()/gn:element/@ref}"
                   lang="{@id}"></value>

            <!--<xsl:message>value alt 1: <xsl:value-of select="$theElement/parent::node()/gn:element/@ref" /> <xsl:value-of select="@id" /></xsl:message>-->

          </xsl:if>
        </xsl:for-each>
      </values>
    </xsl:variable>

    <xsl:call-template name="render-element">
      <xsl:with-param name="label"
                      select="$labelConfig"/>
      <xsl:with-param name="value" select="$values"/>
      <xsl:with-param name="cls" select="local-name()"/>
      <xsl:with-param name="xpath" select="$xpath"/>
      <xsl:with-param name="directive" select="'gn-country-selector-ec'"/>
      <xsl:with-param name="editInfo" select="gn:element"/>
      <xsl:with-param name="parentEditInfo" select="../gn:element"/>
    </xsl:call-template>

  </xsl:template>

  <xsl:template mode="mode-iso19139" match="gmd:administrativeArea" priority="2000">

    <xsl:variable name="xpath" select="gn-fn-metadata:getXPath(.)"/>
    <xsl:variable name="isoType" select="if (../@gco:isoType) then ../@gco:isoType else ''"/>
    <xsl:variable name="labelConfig" select="gn-fn-metadata:getLabel($schema, name(), $labels, name(..), $isoType, $xpath)"/>

    <xsl:variable name="theElement" select="." />

    <xsl:variable name="values">
      <values>
        <!-- Or the PT_FreeText element matching the main language -->
        <xsl:if test="gco:CharacterString">
          <!--<xsl:message>V: <xsl:value-of select="gco:CharacterString" /></xsl:message>-->
          <value ref="{gco:CharacterString/gn:element/@ref}" lang="{$metadataLanguage}">
            <xsl:value-of select="gco:CharacterString"/>
          </value>
          <!--<xsl:message>value main: <xsl:value-of select="gco:CharacterString" /> - <xsl:value-of select="gco:CharacterString/gn:element/@ref" /></xsl:message>-->
        </xsl:if>

        <!-- the existing translation -->
        <xsl:for-each select="gmd:PT_FreeText/gmd:textGroup/gmd:LocalisedCharacterString">
          <value ref="{gn:element/@ref}" lang="{substring-after(@locale, '#')}">
            <xsl:value-of select="."/>
          </value>
          <!--<xsl:message>value alt 1:  <xsl:value-of select="." /> - <xsl:value-of select="gn:element/@ref" /> <xsl:value-of select="substring-after(@locale, '#')" /></xsl:message>-->
        </xsl:for-each>

        <!-- and create field for none translated language -->
        <xsl:for-each select="$metadataOtherLanguages/lang">
          <xsl:variable name="currentLanguageId" select="@id"/>
          <xsl:if test="count($theElement/
                gmd:PT_FreeText/gmd:textGroup/
                gmd:LocalisedCharacterString[@locale = concat('#',$currentLanguageId)]) = 0">
            <value ref="lang_{@id}_{$theElement/parent::node()/gn:element/@ref}"
                   lang="{@id}"></value>

            <!--<xsl:message>value alt 1: <xsl:value-of select="$theElement/parent::node()/gn:element/@ref" /> <xsl:value-of select="@id" /></xsl:message>-->

          </xsl:if>
        </xsl:for-each>
      </values>
    </xsl:variable>

    <xsl:call-template name="render-element">
      <xsl:with-param name="label"
                      select="$labelConfig"/>
      <xsl:with-param name="value" select="$values"/>
      <xsl:with-param name="cls" select="local-name()"/>
      <xsl:with-param name="xpath" select="$xpath"/>
      <xsl:with-param name="directive" select="'gn-state-selector-ec'"/>
      <xsl:with-param name="editInfo" select="gn:element"/>
      <xsl:with-param name="parentEditInfo" select="../gn:element"/>
    </xsl:call-template>

  </xsl:template>


  <!-- Distribution format: Show list of allowed formats -->
  <xsl:template mode="mode-iso19139" match="//gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name" priority="2005">
    <xsl:param name="schema" select="$schema" required="no"/>
    <xsl:param name="labels" select="$labels" required="no"/>
    <xsl:param name="codelists" select="$codelists" required="no"/>
    <xsl:param name="overrideLabel" select="''" required="no"/>

    <xsl:variable name="xpath" select="gn-fn-metadata:getXPath(.)"/>
    <xsl:variable name="isoType" select="if (../@gco:isoType) then ../@gco:isoType else ''"/>
    <xsl:variable name="elementName" select="name()"/>

    <xsl:variable name="listOfValues">
      <entries>
        <xsl:for-each select="$resourceFormatsTh/rdf:RDF/rdf:Description[ns2:prefLabel]">
          <entry>
            <code><xsl:value-of select="replace(@rdf:about, 'http://geonetwork-opensource.org/EC/resourceformat#', '')" /></code>
            <label> <xsl:value-of select="ns2:prefLabel[@xml:lang='en']" /></label>
          </entry>
        </xsl:for-each>
      </entries>
    </xsl:variable>

    <xsl:call-template name="render-element">
      <xsl:with-param name="label"
                      select="if ($overrideLabel != '') then $overrideLabel else gn-fn-metadata:getLabel($schema, name(), $labels, name(..), $isoType, $xpath)"/>
      <xsl:with-param name="value" select="gco:CharacterString"/>
      <xsl:with-param name="cls" select="local-name()"/>
      <xsl:with-param name="xpath" select="$xpath"/>
      <xsl:with-param name="type" select="'select'"/>
      <xsl:with-param name="name"
                      select="*[1]/gn:element/@ref"/>
      <xsl:with-param name="editInfo" select="*[1]/gn:element"/>
      <xsl:with-param name="parentEditInfo" select="gn:element"/>
      <xsl:with-param name="listOfValues"
                      select="$listOfValues/entries"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template mode="mode-iso19139" match="gmd:EX_GeographicBoundingBox" priority="2005">
    <xsl:param name="schema" select="$schema" required="no"/>
    <xsl:param name="labels" select="$labels" required="no"/>

    <xsl:variable name="xpath" select="gn-fn-metadata:getXPath(.)"/>
    <xsl:variable name="isoType" select="if (../@gco:isoType) then ../@gco:isoType else ''"/>
    <xsl:variable name="labelConfig" select="gn-fn-metadata:getLabel($schema, name(), $labels, name(..), $isoType, $xpath)"/>


    <xsl:variable name="hideDelete" as="xs:boolean">
      <xsl:choose>
        <xsl:when test="count(//gmd:EX_GeographicBoundingBox) > 1"><xsl:value-of select="false()" /></xsl:when>
        <xsl:otherwise><xsl:value-of select="true()" /></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:call-template name="render-boxed-element">
      <xsl:with-param name="label"
                      select="$labelConfig/label"/>
      <xsl:with-param name="editInfo" select="../gn:element"/>
      <xsl:with-param name="cls" select="local-name()"/>
      <xsl:with-param name="hideDelete" select="$hideDelete" />
      <xsl:with-param name="subTreeSnippet">

        <xsl:variable name="identifier"
                      select="../following-sibling::gmd:geographicElement[1]/gmd:EX_GeographicDescription/
                                  gmd:geographicIdentifier/gmd:MD_Identifier/gmd:code/(gmx:Anchor|gco:CharacterString)"/>
        <xsl:variable name="description"
                      select="../preceding-sibling::gmd:description/gco:CharacterString"/>
        <xsl:variable name="readonly" select="ancestor-or-self::node()[@xlink:href] != ''"/>
        <div gn-draw-bbox=""
             data-hleft="{gmd:westBoundLongitude/gco:Decimal}"
             data-hright="{gmd:eastBoundLongitude/gco:Decimal}"
             data-hbottom="{gmd:southBoundLatitude/gco:Decimal}"
             data-htop="{gmd:northBoundLatitude/gco:Decimal}"
             data-hleft-ref="_{gmd:westBoundLongitude/gco:Decimal/gn:element/@ref}"
             data-hright-ref="_{gmd:eastBoundLongitude/gco:Decimal/gn:element/@ref}"
             data-hbottom-ref="_{gmd:southBoundLatitude/gco:Decimal/gn:element/@ref}"
             data-htop-ref="_{gmd:northBoundLatitude/gco:Decimal/gn:element/@ref}"
             data-lang="lang"
             data-read-only="{$readonly}">
          <xsl:if test="$identifier and $isFlatMode">
            <xsl:attribute name="data-identifier"
                           select="$identifier"/>
            <xsl:attribute name="data-identifier-ref"
                           select="concat('_', $identifier/gn:element/@ref)"/>
          </xsl:if>
          <xsl:if test="$description and $isFlatMode and not($metadataIsMultilingual)">
            <xsl:attribute name="data-description"
                           select="$description"/>
            <xsl:attribute name="data-description-ref"
                           select="concat('_', $description/gn:element/@ref)"/>
          </xsl:if>
        </div>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


  <xsl:template mode="mode-iso19139" priority="2005"
                match="gmd:linkage1111">
    <xsl:param name="schema" select="$schema" required="no"/>
    <xsl:param name="labels" select="$labels" required="no"/>
    <xsl:param name="overrideLabel" select="''" required="no"/>

    <xsl:variable name="xpath" select="gn-fn-metadata:getXPath(.)"/>
    <xsl:variable name="isoType" select="if (../@gco:isoType) then ../@gco:isoType else ''"/>
    <xsl:variable name="elementName" select="name()"/>

    <!--<xsl:message>gmd:linkage ref: <xsl:copy-of select="*/gn:element" /></xsl:message>
    <xsl:message>gmd:linkage $xpath: <xsl:value-of select="$xpath" /></xsl:message>-->

    <xsl:call-template name="render-element">
      <xsl:with-param name="label"
                      select="if ($overrideLabel != '') then $overrideLabel else gn-fn-metadata:getLabel($schema, name(gmd:URL), $labels, name(), $isoType, $xpath)"/>
      <xsl:with-param name="value" select="gmd:URL"/>
      <xsl:with-param name="cls" select="local-name()"/>
      <xsl:with-param name="xpath" select="$xpath"/>
      <xsl:with-param name="name"
                      select="*/gn:element/@ref"/>
      <xsl:with-param name="editInfo" select="*/gn:element"/>

    </xsl:call-template>

  </xsl:template>
  <!-- Metadata resources template -->
  <xsl:template mode="mode-iso19139"  match="//gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions[1]" priority="2005" />

  <xsl:template mode="mode-iso19139" priority="5000"
                match="gmd:descriptiveKeywords">
    <xsl:param name="schema" select="$schema" required="no"/>
    <xsl:param name="labels" select="$labels" required="no"/>
    <xsl:param name="overrideLabel" select="''" required="no"/>

    <xsl:variable name="xpath" select="gn-fn-metadata:getXPath(.)"/>
    <xsl:variable name="isoType" select="if (../@gco:isoType) then ../@gco:isoType else ''"/>
    <xsl:variable name="thesaurusTitleEl"
                  select="gmd:MD_Keywords/gmd:thesaurusName/gmd:CI_Citation/gmd:title"/>

    <!--<xsl:message>descriptiveKeywords title: <xsl:value-of select="$thesaurusTitleEl/gco:CharacterString" /></xsl:message>-->

    <!--Add all Thesaurus as first block of keywords-->
    <xsl:if test="name(preceding-sibling::*[1]) != name()">
      <xsl:call-template name="addAllThesaurus">
        <xsl:with-param name="ref" select="../gn:element/@ref"/>
      </xsl:call-template>
    </xsl:if>

    <xsl:variable name="thesaurusTitle">
      <xsl:choose>
        <xsl:when test="normalize-space($thesaurusTitleEl/gco:CharacterString) != ''">
          <xsl:value-of select="if ($overrideLabel != '')
              then $overrideLabel
              else concat(
                      $iso19139strings/keywordFrom,
                      normalize-space($thesaurusTitleEl/gco:CharacterString))"/>
        </xsl:when>
        <xsl:when test="normalize-space($thesaurusTitleEl/gmd:PT_FreeText/
                          gmd:textGroup/gmd:LocalisedCharacterString[
                            @locale = concat('#', upper-case(xslutil:twoCharLangCode($lang)))][1]) != ''">
          <xsl:value-of
            select="$thesaurusTitleEl/gmd:PT_FreeText/gmd:textGroup/gmd:LocalisedCharacterString[@locale = concat('#', upper-case(xslutil:twoCharLangCode($lang)))][1]"/>
        </xsl:when>
        <xsl:when test="$thesaurusTitleEl/gmd:PT_FreeText/
                          gmd:textGroup/gmd:LocalisedCharacterString[
                            normalize-space(text()) != ''][1]">
          <xsl:value-of select="$thesaurusTitleEl/gmd:PT_FreeText/gmd:textGroup/
                                  gmd:LocalisedCharacterString[normalize-space(text()) != ''][1]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="gmd:MD_Keywords/gmd:thesaurusName/
                                  gmd:CI_Citation/gmd:identifier/gmd:MD_Identifier/gmd:code"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>


    <xsl:variable name="attributes">
      <xsl:if test="$isEditing">
        <!-- Create form for all existing attribute (not in gn namespace)
        and all non existing attributes not already present. -->
        <xsl:apply-templates mode="render-for-field-for-attribute"
                             select="
          @*|
          gn:attribute[not(@name = parent::node()/@*/name())]">
          <xsl:with-param name="ref" select="gn:element/@ref"/>
          <xsl:with-param name="insertRef" select="gn:element/@ref"/>
        </xsl:apply-templates>
      </xsl:if>
    </xsl:variable>


    <xsl:variable name="thesaurusIdentifier"
                  select="normalize-space($thesaurusTitle)"/>

    <xsl:variable name="thesaurusConfig"
                  as="element()?"
                  select="if ($thesaurusList/thesaurus[@key=substring-after($thesaurusIdentifier, 'geonetwork.thesaurus.')])
                          then $thesaurusList/thesaurus[@key=substring-after($thesaurusIdentifier, 'geonetwork.thesaurus.')]
                          else $listOfThesaurus/thesaurus[title=$thesaurusTitle]"/>

    <xsl:choose>
      <xsl:when test="$thesaurusConfig/@fieldset = 'false'">

        <xsl:apply-templates mode="mode-iso19139" select="*">
          <xsl:with-param name="schema" select="$schema"/>
          <xsl:with-param name="labels" select="$labels"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="hideDelete" as="xs:boolean">
          <xsl:choose>
            <xsl:when test="ends-with($thesaurusTitle,  'Government of Canada Core Subject Thesaurus') or
                  ends-with($thesaurusTitle,  'Thésaurus des sujets de base du gouvernement du Canada')">
              <xsl:value-of select="true()" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="false()" /></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:call-template name="render-boxed-element">
          <xsl:with-param name="label"
                          select="if ($thesaurusTitle !='')
                    then $thesaurusTitle
                    else gn-fn-metadata:getLabel($schema, name(), $labels, name(..), $isoType, $xpath)/label"/>
          <xsl:with-param name="editInfo" select="gn:element"/>
          <xsl:with-param name="cls" select="local-name()"/>
          <xsl:with-param name="xpath" select="$xpath"/>
          <xsl:with-param name="attributesSnippet" select="$attributes"/>
          <xsl:with-param name="hideDelete" select="$hideDelete" />
          <xsl:with-param name="subTreeSnippet">
            <xsl:apply-templates mode="mode-iso19139" select="*">
              <xsl:with-param name="schema" select="$schema"/>
              <xsl:with-param name="labels" select="$labels"/>
            </xsl:apply-templates>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>


  <xsl:template mode="mode-iso19139" match="gmd:MD_Keywords" priority="5000">


    <xsl:variable name="thesaurusIdentifier"
                  select="normalize-space(gmd:thesaurusName/gmd:CI_Citation/gmd:title/gco:CharacterString)"/>


    <xsl:variable name="thesaurusTitle"
                  select="gmd:thesaurusName/gmd:CI_Citation/gmd:title/(gco:CharacterString|gmd:PT_FreeText/gmd:textGroup/gmd:LocalisedCharacterString)"/>

    <!--<xsl:message>THESAURUS TITLE C:<xsl:copy-of select="/root/gui/schemas/iso19139.napec" /></xsl:message>-->
    <xsl:variable name="thesaurusTitle2">
      <xsl:choose>
        <xsl:when test="(gmd:thesaurusName/gmd:CI_Citation/gmd:title/gco:CharacterString = 'Government of Canada Core Subject Thesaurus') or
                  (gmd:thesaurusName/gmd:CI_Citation/gmd:title/gco:CharacterString = 'Thésaurus des sujets de base du gouvernement du Canada')">
          <xsl:value-of  select="'local.theme.EC_Core_Subject'"/>
        </xsl:when>

        <xsl:otherwise>
          <xsl:value-of  select="normalize-space(gmd:thesaurusName/gmd:CI_Citation/gmd:title/gco:CharacterString)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!--<xsl:message>thesaurusIdentifier: <xsl:value-of select="$thesaurusIdentifier" /></xsl:message>
    <xsl:message>thesaurusTitle: <xsl:value-of select="$thesaurusTitle" /></xsl:message>
    <xsl:message>thesaurusTitle2: <xsl:value-of select="$thesaurusTitle2" /></xsl:message>
    <xsl:message>thesaurusIdentifier substring: <xsl:value-of select="substring-after($thesaurusIdentifier, 'local.')" /></xsl:message>-->

    <!--<xsl:message>thesaurusTitle2: <xsl:value-of select="$thesaurusTitle2" /></xsl:message>-->

    <xsl:variable name="thesaurusConfig"
                  as="element()?"
                  select="if ($thesaurusList/thesaurus[@key=substring-after($thesaurusIdentifier, 'geonetwork.thesaurus.')])
                          then $thesaurusList/thesaurus[@key=substring-after($thesaurusIdentifier, 'geonetwork.thesaurus.')]
                          else if ($listOfThesaurus/thesaurus[title=$thesaurusIdentifier])
                          then $listOfThesaurus/thesaurus[title=$thesaurusIdentifier]
                          else if ($listOfThesaurus/thesaurus[title=$thesaurusTitle])
                          then $listOfThesaurus/thesaurus[title=$thesaurusTitle2]
                          else $listOfThesaurus/thesaurus[key=$thesaurusTitle2]"/>
    <!--<xsl:message>thesaurusConfig: <xsl:copy-of select="$thesaurusConfig" /></xsl:message>

    <xsl:for-each select="$listOfThesaurus/thesaurus">
      <xsl:message>
        $listOfThesaurus: <xsl:value-of select="key" /> - <xsl:value-of select="title" />
      </xsl:message>
    </xsl:for-each>

    <xsl:for-each select="$thesaurusList/thesaurus">
      <xsl:message>
        $thesaurusList: <xsl:value-of select="@key" />
      </xsl:message>
    </xsl:for-each>-->


    <xsl:choose>
      <xsl:when test="$thesaurusConfig">

        <xsl:variable name="thesaurusIdentifier"
                      select="$thesaurusConfig/key"/>

        <!-- The thesaurus key may be contained in the MD_Identifier field or
          get it from the list of thesaurus based on its title.
          -->
        <xsl:variable name="thesaurusInternalKey"
                      select="if ($thesaurusIdentifier)
          then $thesaurusIdentifier
          else $thesaurusConfig/key"/>
        <xsl:variable name="thesaurusKey"
                      select="if (starts-with($thesaurusInternalKey, 'geonetwork.thesaurus.'))
                      then substring-after($thesaurusInternalKey, 'geonetwork.thesaurus.')
                      else $thesaurusInternalKey"/>

        <!-- if gui lang eng > #EN -->
        <xsl:variable name="guiLangId"
                      select="
                      if (count($metadata/gmd:locale/gmd:PT_Locale[gmd:languageCode/gmd:LanguageCode/@codeListValue = $lang]) = 1)
                        then $metadata/gmd:locale/gmd:PT_Locale[gmd:languageCode/gmd:LanguageCode/@codeListValue = $lang]/@id
                        else $metadata/gmd:locale/gmd:PT_Locale[gmd:languageCode/gmd:LanguageCode/@codeListValue = $metadataLanguage]/@id"/>

        <!--
        get keyword in gui lang
        in default language
        -->
        <xsl:variable name="keywords" select="string-join(
                  if ($guiLangId and gmd:keyword//*[@locale = concat('#', $guiLangId)]) then
                    gmd:keyword//*[@locale = concat('#', $guiLangId)]/replace(text(), ',', ',,')
                  else gmd:keyword/*[1]/replace(text(), ',', ',,'), ',')"/>

        <!-- Define the list of transformation mode available. -->
        <!--<xsl:variable name="transformations"
                      as="xs:string"
                      select="if ($thesaurusConfig/@transformations != '')
                              then $thesaurusConfig/@transformations
                              else 'to-iso19139-keyword,to-iso19139-keyword-with-anchor,to-iso19139-keyword-as-xlink'"/>-->
        <xsl:variable name="transformations" select="''" />

        <!-- Get current transformation mode based on XML fragment analysis -->
        <xsl:variable name="transformation"
                      select="if (parent::node()/@xlink:href) then 'to-iso19139-keyword-as-xlink'
          else if (count(gmd:keyword/gmx:Anchor) > 0)
          then 'to-iso19139-keyword-with-anchor'
          else 'to-iso19139-keyword'"/>

        <xsl:variable name="parentName" select="name(..)"/>

        <!-- Create custom widget:
              * '' for item selector,
              * 'tagsinput' for tags
              * 'tagsinput' and maxTags = 1 for only one tag
              * 'multiplelist' for multiple selection list
        -->
        <xsl:variable name="widgetMode" select="'tagsinput'"/>
        <xsl:variable name="maxTags"
                      as="xs:string"
                      select="if ($thesaurusConfig/@maxtags)
                              then $thesaurusConfig/@maxtags
                              else ''"/>
        <!--
          Example: to restrict number of keyword to 1 for INSPIRE
          <xsl:variable name="maxTags"
          select="if ($thesaurusKey = 'external.theme.inspire-theme') then '1' else ''"/>
        -->
        <!-- Create a div with the directive configuration
            * elementRef: the element ref to edit
            * elementName: the element name
            * thesaurusName: the thesaurus title to use
            * thesaurusKey: the thesaurus identifier
            * keywords: list of keywords in the element
            * transformations: list of transformations
            * transformation: current transformation
          -->

        <xsl:variable name="allLanguages"
                      select="concat($metadataLanguage, ',', $metadataOtherLanguages)"></xsl:variable>

        <xsl:variable name="thesaurusTitleToDisplay">
          <xsl:choose>
            <xsl:when test="contains($thesaurusIdentifier, 'EC_')">
              <xsl:value-of select="/root/gui/schemas/iso19139.napec/strings/*[name() = $thesaurusIdentifier]" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$thesaurusTitle" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <!--<xsl:message>
          $thesaurusIdentifier: <xsl:value-of select="$thesaurusIdentifier" />
          $thesaurusTitleToDisplay: <xsl:value-of select="thesaurusTitleToDisplay" />

        </xsl:message>-->

        <xsl:variable name="isMandatory">
          <xsl:choose>
            <xsl:when test="contains($thesaurusIdentifier, 'EC_Information_Category') or
                            contains($thesaurusIdentifier, 'EC_Geographic_Scope') or
                            contains($thesaurusIdentifier, 'EC_Core_Subject')">true</xsl:when>
            <xsl:otherwise>false</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <!-- $thesaurusIdentifier add label for keywords in Information Classification panel -->
        <div data-gn-keyword-selector="{$widgetMode}"
             data-metadata-id="{$metadataId}"
             data-element-ref="{concat('_X', ../gn:element/@ref, '_replace')}"
             data-parent-element-ref="{gmd:keyword[1]/gn:element/@ref}"
             data-thesaurus-title="{if ($thesaurusConfig/@fieldset = 'false' or contains($thesaurusIdentifier, 'EC_')) then $thesaurusTitleToDisplay else ''}"
             data-thesaurus-key="{$thesaurusKey}"
             data-mandatory="{$isMandatory}"
             data-keywords="{$keywords}"
             data-transformations="{$transformations}"
             data-current-transformation="{$transformation}"
             data-max-tags="{$maxTags}"
             data-lang="{$metadataOtherLanguagesAsJson}"
             data-textgroup-only="false">
        </div>

        <!-- TODO: To check for ECCC -->
        <!--<xsl:variable name="isTypePlace"
                      select="count(gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='place']) > 0"/>
        <xsl:if test="$isTypePlace">
          <xsl:call-template name="render-batch-process-button">
            <xsl:with-param name="process-name" select="'add-extent-from-geokeywords'"/>
            <xsl:with-param name="process-params">{"replace": true}</xsl:with-param>
          </xsl:call-template>
        </xsl:if>-->

        <div class="col-sm-offset-2 col-sm-9">
          <xsl:call-template name="get-errors-2">
            <xsl:with-param name="refToUse" select="gmd:keyword[1]/gn:element/@ref" />
          </xsl:call-template>
        </div>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="mode-iso19139" select="*"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>


  <xsl:template mode="mode-iso19139" match="gmd:EX_BoundingPolygon" priority="5000">
    <xsl:param name="schema" select="$schema" required="no"/>
    <xsl:param name="labels" select="$labels" required="no"/>

    <xsl:variable name="xpath" select="gn-fn-metadata:getXPath(.)"/>
    <xsl:variable name="isoType" select="if (../@gco:isoType) then ../@gco:isoType else ''"/>
    <xsl:variable name="labelConfig" select="gn-fn-metadata:getLabel($schema, name(), $labels, name(..), $isoType, $xpath)"/>

    <xsl:call-template name="render-boxed-element">
      <xsl:with-param name="label"
                      select="$labelConfig/label"/>
      <xsl:with-param name="editInfo" select="../gn:element"/>
      <xsl:with-param name="cls" select="local-name()"/>
      <xsl:with-param name="subTreeSnippet">

        <xsl:variable name="geometry">
          <xsl:apply-templates select="gmd:polygon/gml:MultiSurface|gmd:polygon/gml:LineString|gmd:polygon/gml:Polygon"
                               mode="gn-element-cleaner"/>
        </xsl:variable>

        <xsl:variable name="identifier"
                      select="concat('_X', gmd:polygon/gn:element/@ref, '_replace')"/>
        <xsl:variable name="readonly" select="ancestor-or-self::node()[@xlink:href] != ''"/>

        <br />
        <gn-bounding-polygon polygon-xml="{saxon:serialize($geometry, 'default-serialize-mode')}"
                             identifier="{$identifier}"
                             read-only="{$readonly}">
        </gn-bounding-polygon>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
