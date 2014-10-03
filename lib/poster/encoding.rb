require 'cgi'
require 'nokogiri'

module Poster
  module Encoding

    # Bitcointalk uses really weird representation for Russian letters:
    # XML character entities (Cyrillic) - ISOCYR1
    # http://www.w3.org/2003/entities/iso8879doc/isocyr1.html
    XML_ENTITIES = Hash[
      *%w[
        а 1072
        б 1073
        в 1074
        г 1075
        д 1076
        е 1077
        ё 1105
        ж 1078
        з 1079
        и 1080
        й 1081
        к 1082
        л 1083
        м 1084
        н 1085
        о 1086
        п 1087
        р 1088
        с 1089
        т 1090
        у 1091
        ф 1092
        х 1093
        ц 1094
        ч 1095
        ш 1096
        щ 1097
        ъ 1098
        ы 1099
        ь 1100
        э 1101
        ю 1102
        я 1103
        А	1040
        Б	1041
        В	1042
        Г	1043
        Д	1044
        Е	1045
        Ё	1025
        Ж	1046
        З	1047
        И	1048
        Й	1049
        К	1050
        Л	1051
        М	1052
        Н	1053
        О	1054
        П	1055
        Р	1056
        С	1057
        Т	1058
        У	1059
        Ф	1060
        Х	1061
        Ц	1062
        Ч	1063
        Ш	1064
        Щ	1065
        Ъ	1066
        Ы	1067
        Ь	1068
        Э	1069
        Ю	1070
        Я	1071
    ]]

    # List of weird Unicode chars that show up in Russian texts 
    CONVERTIBLES = Hash[
      *%W[
        « "
        » "
        – -
        — -
        − -
        — -
        − -
        \xC2\xA0 \x20
    ]]

    HOMOGLYPHS = Hash[
      *%w[
        а a
        е e
        ё e
        и u
        о o
        п n
        р p
        с c
        у y
        х x
        А	A
        В	B
        Е	E
        Ё	E
        З	3
        К	K
        М	M
        Н	H
        О	O
        Р	P
        С	C
        Т	T
        Х	X
        Ь	b
        « "
        » "
        — -
        − -
    ]]

    # Encode Russian UTF-8 string to XML Entities format, 
    # converting weird Unicode chars along the way
    def xml_encode string
      puts string.each_char.size
      string.each_char.map do |p|
        case 
        when CONVERTIBLES[p]
          CONVERTIBLES[p]
        when XML_ENTITIES[p]
          "&##{XML_ENTITIES[p]};"
        else
          p
        end
      end.reduce(:+)
    end

    # Encode Russian UTF-8 chars to similar English chars (for compactness)
    def subj_encode string
      puts string.each_char.size
      string.each_char.map do |p|
        HOMOGLYPHS[p] ? HOMOGLYPHS[p] : p
      end.reduce(:+)
    end

    def strip_tags string
      Nokogiri::HTML(CGI.unescapeHTML(string)).content
    end
  end
end
