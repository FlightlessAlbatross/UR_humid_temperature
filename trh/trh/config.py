#config.py

from pathlib import Path
import os
from typing import Tuple

package_dir = Path(os.path.dirname(os.path.dirname(__file__)))
data_dir = package_dir.parent / 'data'