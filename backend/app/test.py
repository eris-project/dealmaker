import unittest
import yaml

class TestCards(unittest.TestCase):

    def test_deck(self):
        def gen_cards(card_type: str, cards: list) -> list:
            card_list = []
            for card in cards:
                metadata = card.pop('metadata')
                count = metadata['count']
                card['card_type'] = card_type
                for _ in range(count):
                    card_list.append(card)
            return card_list

        card_file = r'src/data/cards.yml'
        with open(card_file, 'r') as f:
            cards = yaml.safe_load(f)['cards']
            money_cards = cards['card_types']['money']
            action_cards = cards['card_types']['action']
            property_cards = cards['card_types']['property']

            all_money_cards = gen_cards('money', money_cards)
            all_action_cards = gen_cards('action', action_cards)
            all_property_cards = gen_cards('property', property_cards)

        print(all_money_cards)
        print()
        print(all_action_cards)
        print()
        print(all_property_cards)


if __name__ == '__main__':
    unittest.main()