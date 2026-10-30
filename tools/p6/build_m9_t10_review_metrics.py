"""Derive review-only economic observations from valid final earned-run records."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ap = argparse.ArgumentParser()
ap.add_argument('folders', nargs='+')
args = ap.parse_args()
rows = []
for folder in args.folders:
    for path in sorted((ROOT / 'project/reports/m9_t10' / folder).glob('*.json')):
        data = json.loads(path.read_text(encoding='utf-8-sig'))
        if not isinstance(data, dict) or not data.get('fights'):
            continue
        assert not data['validity_failures'], path
        offers = [e for e in data['events'] if e['action'] == 'shop_offer']
        # Raw offer-time price uses actual resolved discount; do not infer rarity incidence
        # from a deliberately selected diagnostic or extrapolate infinite rerolls.
        # Resolve named enum identities rather than assume their numeric order.
        from re import search, M
        enum_text = (ROOT/'project/scripts/resources/gear_item.gd').read_text()
        # Tier order: verified at report generation, with named source values.
        tier_enum = search(r'enum Tier\s*\{([^}]+)', enum_text).group(1)
        names = [n.strip().split('=')[0].strip() for n in tier_enum.split(',') if n.strip()]
        price_names = {'BASIC':18,'MASTER':32,'EPIC':46,'CURSED':40,'CHAOS':55,'UNIQUE':70,'LEGENDARY':80,'CRUDE':0}
        bases = {i:price_names[n] for i,n in enumerate(names)}
        profit_offers = []
        for e in offers:
            item=e['item']
            tier=item.get('tier')
            if tier is None:
                text=(ROOT/'project'/item['resource_path'].removeprefix('res://')).read_text()
                m=search(r'^tier = (\d+)',text,M)
                tier=int(m[1]) if m else 0
            resale=max(1,bases[tier]//2)
            if e['price'] < resale:
                profit_offers.append({'stage':e['stage'],'price':e['price'],'resale':resale})
        bands={}
        for band in ['Tavern','C1-C3','C4-C8','C9-C13']:
            selected=[e for e in offers if ('Tavern' if e['stage'].startswith('T') else
                      'C1-C3' if int(e['stage'][1:])<=3 else
                      'C4-C8' if int(e['stage'][1:])<=8 else 'C9-C13') == band]
            bands[band]={'offer_observations':len(selected),
                         'unaffordable_at_observation':sum(not e['affordable'] for e in selected)}
        rows.append({'arm':data['arm'],'build':data['build'],'seed':data['seed'],
                     'variant':data.get('variant','fixed'),'source':str(path.relative_to(ROOT)),
                     'affordability':bands,'profitable_resale_offer_observations':profit_offers,
                     'shop_stages':sorted({e['stage'] for e in offers}),
                     'all_currency_reconciles':sum(e['delta'] for e in data['events'])==data['gold']})
out=ROOT/'project/reports/m9_t10/review_metrics.json'
out.write_text(json.dumps(rows,indent=2)+'\n')
print(json.dumps(rows,indent=2))
